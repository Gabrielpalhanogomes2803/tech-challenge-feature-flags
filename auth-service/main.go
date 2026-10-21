package main

import (
	"database/sql"
	"net/http"
	"os"

	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/joho/godotenv"
)

type App struct {
	DB        *sql.DB
	MasterKey string
}

func main() {
	_ = godotenv.Load()

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

	writeLog("info", "service_started", LogEvent{
		Component: "http-server",
		Message:   "auth-service started",
	})

	if err := http.ListenAndServe(":"+port, mux); err != nil {
		fatalLog("http_server_failed", LogEvent{
			Component: "http-server",
			Message:   "HTTP server stopped unexpectedly",
		})
	}
}
