package main

import (
	"context"
	"net/http"
	"os"
	"time"

	"evaluation-service/internal/telemetry"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	"github.com/go-redis/redis/v8"
	"github.com/joho/godotenv"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

type App struct {
	RedisClient         *redis.Client
	SqsSvc              *sqs.SQS
	SqsQueueURL         string
	HttpClient          *http.Client
	FlagServiceURL      string
	TargetingServiceURL string
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
		port = "8004"
	}

	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		fatalLog("required_configuration_missing", LogEvent{
			Component: "configuration",
			Message:   "REDIS_URL is not configured",
		})
	}

	flagSvcURL := os.Getenv("FLAG_SERVICE_URL")
	if flagSvcURL == "" {
		fatalLog("required_configuration_missing", LogEvent{
			Component: "configuration",
			Message:   "FLAG_SERVICE_URL is not configured",
		})
	}

	targetingSvcURL := os.Getenv("TARGETING_SERVICE_URL")
	if targetingSvcURL == "" {
		fatalLog("required_configuration_missing", LogEvent{
			Component: "configuration",
			Message:   "TARGETING_SERVICE_URL is not configured",
		})
	}

	sqsQueueURL := os.Getenv("AWS_SQS_URL")
	awsEndpointURL := os.Getenv("AWS_ENDPOINT_URL")
	awsRegion := os.Getenv("AWS_REGION")

	if awsRegion == "" && sqsQueueURL != "" {
		fatalLog("required_configuration_missing", LogEvent{
			Component: "configuration",
			Message:   "AWS_REGION is required when SQS is enabled",
		})
	}

	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		fatalLog("redis_configuration_error", LogEvent{
			Component:  "cache",
			Dependency: "redis",
			Message:    "failed to parse Redis URL",
		})
	}

	rdb := redis.NewClient(opt)

	if _, err := rdb.Ping(context.Background()).Result(); err != nil {
		fatalLog("redis_connection_failed", LogEvent{
			Component:  "cache",
			Dependency: "redis",
			Message:    "Redis ping failed",
		})
	}

	writeLog("info", "redis_connected", LogEvent{
		Component:  "cache",
		Dependency: "redis",
	})

	var sqsSvc *sqs.SQS

	if sqsQueueURL != "" {
		awsConfig := &aws.Config{Region: aws.String(awsRegion)}

		if awsEndpointURL != "" {
			awsConfig.Endpoint = aws.String(awsEndpointURL)
			awsConfig.DisableSSL = aws.Bool(true)
		}

		sess, err := session.NewSession(awsConfig)
		if err != nil {
			fatalLog("aws_client_initialization_failed", LogEvent{
				Component:  "queue",
				Dependency: "sqs",
				Message:    "failed to initialize AWS session",
			})
		}

		sqsSvc = sqs.New(sess)

		writeLog("info", "sqs_client_initialized", LogEvent{
			Component:  "queue",
			Dependency: "sqs",
		})
	}

	// O transport instrumentado cria um span de cliente para cada chamada ao
	// flag-service e ao targeting-service e envia o header traceparent.
	httpClient := &http.Client{
		Timeout:   5 * time.Second,
		Transport: otelhttp.NewTransport(http.DefaultTransport),
	}

	app := &App{
		RedisClient:         rdb,
		SqsSvc:              sqsSvc,
		SqsQueueURL:         sqsQueueURL,
		HttpClient:          httpClient,
		FlagServiceURL:      flagSvcURL,
		TargetingServiceURL: targetingSvcURL,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", app.healthHandler)
	mux.HandleFunc("/live", app.liveHandler)
	mux.HandleFunc("/evaluate", app.evaluationHandler)

	// Um span por requisição recebida. Probes ficam de fora para não poluir o APM.
		handler := otelhttp.NewHandler(mux, "evaluation-service",
		otelhttp.WithFilter(func(r *http.Request) bool {
			return r.URL.Path != "/health" && r.URL.Path != "/live"
		}),
		otelhttp.WithSpanNameFormatter(func(_ string, r *http.Request) string {
			return r.Method + " " + r.URL.Path
		}),
	)

	writeLog("info", "service_started", LogEvent{
		Component: "http-server",
		Message:   "evaluation-service started",
	})

	if err := http.ListenAndServe(":"+port, handler); err != nil {
		fatalLog("http_server_failed", LogEvent{
			Component: "http-server",
			Message:   "HTTP server stopped unexpectedly",
		})
	}
}