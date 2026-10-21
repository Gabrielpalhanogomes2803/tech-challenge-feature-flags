package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

type LogEvent struct {
	Timestamp   string `json:"timestamp"`
	Level       string `json:"level"`
	Service     string `json:"service"`
	Environment string `json:"environment"`
	Event       string `json:"event"`
	Component   string `json:"component,omitempty"`
	Dependency  string `json:"dependency,omitempty"`
	StatusCode  int    `json:"status_code,omitempty"`
	DurationMS  int64  `json:"duration_ms,omitempty"`
	Message     string `json:"message,omitempty"`
}

func writeLog(level, event string, fields LogEvent) {
	fields.Timestamp = time.Now().UTC().Format(time.RFC3339)
	fields.Level = level
	fields.Service = "evaluation-service"
	fields.Event = event

	if fields.Environment == "" {
		fields.Environment = os.Getenv("ENVIRONMENT")
	}

	if fields.Environment == "" {
		fields.Environment = "local"
	}

	payload, err := json.Marshal(fields)
	if err != nil {
		fmt.Fprintf(os.Stderr, `{"level":"error","event":"logging_error","message":"failed to encode log"}`+"\n")
		return
	}

	writer := os.Stdout
	if level == "error" || level == "critical" {
		writer = os.Stderr
	}

	fmt.Fprintln(writer, string(payload))
}

func fatalLog(event string, fields LogEvent) {
	writeLog("critical", event, fields)
	os.Exit(1)
}
