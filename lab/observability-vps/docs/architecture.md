# Phase 4 Observability Architecture

## Objective

Prepare the ToggleMaster observability layer for deployment on AWS EKS.

The final environment uses the Kubernetes workloads as the primary monitoring target. The VPS stack is used only as a validation environment before the AWS deployment.

## Application

ToggleMaster is composed of five microservices:

- auth-service
- flag-service
- targeting-service
- evaluation-service
- analytics-service

## Observability

The planned stack is:

- Prometheus for metrics
- Loki for logs
- Grafana for dashboards
- OpenTelemetry Collector for telemetry processing and export

The OpenTelemetry Collector and distributed tracing integration are handled by the telemetry/APM workstream.

## Logging

Applications write structured JSON logs to stdout.

Standard fields:

- timestamp
- level
- service
- environment
- event

Optional fields include:

- component
- dependency
- status_code
- duration_ms
- request_id
- trace_id
- message

Secrets, credentials and authorization headers must not be logged.

## Kubernetes

The application workloads use:

- multiple replicas
- RollingUpdate deployments
- PodDisruptionBudgets
- topology spread constraints
- HPA on evaluation-service

The production observability stack will be installed in EKS through GitOps.

## Dashboard

The main Grafana dashboard is focused on the ToggleMaster platform:

- EKS cluster health
- pods and deployments
- workload CPU and memory
- request rate
- error rate
- latency
- application logs
- application dependencies

The dashboard does not use synthetic values for unavailable application metrics. These panels are populated after the services and cluster telemetry are available in EKS.
