package main

import (
	"context"
	"database/sql"
	"net/http"
	"os"

	"auth-service/internal/telemetry"

	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/joho/godotenv"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

type App struct {
	DB        *sql.DB
	MasterKey string
}

func main() {
	_ = godotenv.Load()

	// Telemetria (traces via OTLP). Uma falha aqui não derruba o serviço.
	shutdownTelemetry, err := telemetry.Init(context.Background())
	if err != nil {
		writeLog("error", "telemetry_init_failed", LogEvent{
			Component: "telemetry",
			Message:   "failed to initialize OpenTelemetry: " + err.Error(),
		})
	} else {
		defer shutdownTelemetry(context.Background())
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		fatalLog("required_configuration_missing", LogEvent{
			Component: "configuration",
			Message:   "DATABASE_URL is not configured",
		})
	}

	masterKey := os.Getenv("MASTER_KEY")
	if masterKey == "" {
		fatalLog("required_configuration_missing", LogEvent{
			Component: "configuration",
			Message:   "MASTER_KEY is not configured",
		})
	}

	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		fatalLog("database_connection_failed", LogEvent{
			Component:  "database",
			Dependency: "postgresql",
			Message:    "failed to initialize database connection",
		})
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		fatalLog("database_connection_failed", LogEvent{
			Component:  "database",
			Dependency: "postgresql",
			Message:    "database ping failed",
		})
	}

	app := &App{
		DB:        db,
		MasterKey: masterKey,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", app.healthHandler)
	mux.HandleFunc("/live", app.liveHandler)
	mux.HandleFunc("/validate", app.validateKeyHandler)

	mux.Handle(
		"/admin/keys",
		app.masterKeyAuthMiddleware(http.HandlerFunc(app.createKeyHandler)),
	)

	// Falha controlada para demonstracao do Self-Healing.
	// Protegida pela MASTER_KEY e por CHAOS_ENABLED.
	mux.Handle(
		"/admin/chaos",
		app.masterKeyAuthMiddleware(http.HandlerFunc(chaosAdminHandler)),
	)

	// Um span por requisição; continua o trace que chega pelo header traceparent
	// (flag-service, targeting-service e evaluation-service chamam /validate).
	handler := otelhttp.NewHandler(chaosMiddleware(mux), "auth-service",
		otelhttp.WithFilter(func(r *http.Request) bool {
			return r.URL.Path != "/health" && r.URL.Path != "/live"
		}),
		otelhttp.WithSpanNameFormatter(func(_ string, r *http.Request) string {
			return r.Method + " " + r.URL.Path
		}),
	)

	writeLog("info", "service_started", LogEvent{
		Component: "http-server",
		Message:   "auth-service started",
	})

	if err := http.ListenAndServe(":"+port, handler); err != nil {
		fatalLog("http_server_failed", LogEvent{
			Component: "http-server",
			Message:   "HTTP server stopped unexpectedly",
		})
	}
}