package main

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

type CreateKeyRequest struct {
	Name string `json:"name"`
}

type CreateKeyResponse struct {
	Name    string `json:"name"`
	Key     string `json:"key"`
	Message string `json:"message"`
}

func (a *App) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if err := a.DB.PingContext(ctx); err != nil {
		writeLog("error", "health_check_failed", LogEvent{
			Component:  "database",
			Dependency: "postgresql",
			StatusCode: http.StatusServiceUnavailable,
			Message:    "database unavailable",
		})

		w.WriteHeader(http.StatusServiceUnavailable)
		json.NewEncoder(w).Encode(map[string]string{
			"status":   "degraded",
			"database": "down",
		})
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "ok",
		"database": "up",
	})
}

func (a *App) liveHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (a *App) validateKeyHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	keyString := strings.TrimPrefix(authHeader, "Bearer ")

	if keyString == "" {
		writeLog("warn", "auth_validation_failed", LogEvent{
			Component:  "authentication",
			StatusCode: http.StatusUnauthorized,
			Message:    "authorization header missing",
		})

		http.Error(w, "Authorization header não encontrado", http.StatusUnauthorized)
		return
	}

	keyHash := hashAPIKey(keyString)

	var id int

	err := a.DB.QueryRow(
		"SELECT id FROM api_keys WHERE key_hash = $1 AND is_active = true",
		keyHash,
	).Scan(&id)

	if err != nil {
		writeLog("warn", "auth_validation_failed", LogEvent{
			Component:  "authentication",
			StatusCode: http.StatusUnauthorized,
			Message:    "API key validation failed",
		})

		http.Error(w, "Chave de API inválida ou inativa", http.StatusUnauthorized)
		return
	}

	writeLog("info", "auth_validation_success", LogEvent{
		Component:  "authentication",
		StatusCode: http.StatusOK,
	})

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Chave válida",
	})
}

func (a *App) createKeyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método não permitido", http.StatusMethodNotAllowed)
		return
	}

	var req CreateKeyRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Corpo inválido", http.StatusBadRequest)
		return
	}

	if req.Name == "" {
		http.Error(w, "Campo name obrigatório", http.StatusBadRequest)
		return
	}

	newKey, err := generateAPIKey()
	if err != nil {
		http.Error(w, "Erro ao gerar chave", http.StatusInternalServerError)
		return
	}

	newKeyHash := hashAPIKey(newKey)

	var newID int

	err = a.DB.QueryRow(
		"INSERT INTO api_keys (name, key_hash) VALUES ($1, $2) RETURNING id",
		req.Name,
		newKeyHash,
	).Scan(&newID)

	if err != nil {
		writeLog("error", "database_error", LogEvent{
			Component:  "database",
			Dependency: "postgresql",
			StatusCode: http.StatusInternalServerError,
			Message:    "failed to persist API key",
		})

		http.Error(w, "Erro ao salvar chave", http.StatusInternalServerError)
		return
	}

	writeLog("info", "api_key_created", LogEvent{
		Component:  "authentication",
		StatusCode: http.StatusCreated,
	})

	w.WriteHeader(http.StatusCreated)

	json.NewEncoder(w).Encode(CreateKeyResponse{
		Name:    req.Name,
		Key:     newKey,
		Message: "Guarde esta chave com segurança!",
	})
}

func (a *App) masterKeyAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		keyString := strings.TrimPrefix(authHeader, "Bearer ")

		if keyString != a.MasterKey {
			writeLog("warn", "auth_validation_failed", LogEvent{
				Component:  "authentication",
				StatusCode: http.StatusForbidden,
				Message:    "master key validation failed",
			})

			http.Error(w, "Acesso não autorizado", http.StatusForbidden)
			return
		}

		next.ServeHTTP(w, r)
	})
}
