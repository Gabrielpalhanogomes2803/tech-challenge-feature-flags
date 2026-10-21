package main

import (
	"context"
	"encoding/json"
	"net/http"
	"time"
)

type EvaluationResponse struct {
	FlagName string `json:"flag_name"`
	UserID   string `json:"user_id"`
	Result   bool   `json:"result"`
}

func (a *App) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if err := a.RedisClient.Ping(ctx).Err(); err != nil {
		writeLog("error", "health_check_failed", LogEvent{
			Component:  "cache",
			Dependency: "redis",
			StatusCode: http.StatusServiceUnavailable,
			Message:    "Redis unavailable",
		})

		w.WriteHeader(http.StatusServiceUnavailable)
		json.NewEncoder(w).Encode(map[string]string{
			"status": "degraded",
			"redis":  "down",
		})
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"redis":  "up",
	})
}

func (a *App) liveHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (a *App) evaluationHandler(w http.ResponseWriter, r *http.Request) {
	started := time.Now()

	w.Header().Set("Content-Type", "application/json")

	userID := r.URL.Query().Get("user_id")
	flagName := r.URL.Query().Get("flag_name")

	if userID == "" || flagName == "" {
		writeLog("warn", "evaluation_failed", LogEvent{
			Component:  "evaluation",
			StatusCode: http.StatusBadRequest,
			DurationMS: time.Since(started).Milliseconds(),
			Message:    "required query parameters missing",
		})

		http.Error(
			w,
			`{"error": "user_id e flag_name são obrigatórios"}`,
			http.StatusBadRequest,
		)
		return
	}

	result, err := a.getDecision(userID, flagName)
	if err != nil {
		if _, ok := err.(*NotFoundError); ok {
			result = false
		} else {
			writeLog("error", "evaluation_failed", LogEvent{
				Component:  "evaluation",
				StatusCode: http.StatusBadGateway,
				DurationMS: time.Since(started).Milliseconds(),
				Message:    "evaluation dependency failed",
			})

			http.Error(
				w,
				`{"error": "Erro interno ao avaliar a flag"}`,
				http.StatusBadGateway,
			)
			return
		}
	}

	go a.sendEvaluationEvent(userID, flagName, result)

	writeLog("info", "evaluation_success", LogEvent{
		Component:  "evaluation",
		StatusCode: http.StatusOK,
		DurationMS: time.Since(started).Milliseconds(),
	})

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(EvaluationResponse{
		FlagName: flagName,
		UserID:   userID,
		Result:   result,
	})
}
