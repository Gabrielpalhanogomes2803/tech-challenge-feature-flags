# ToggleMaster Observability Matrix

| Area | Signal | Source | Status |
|---|---|---|---|
| Cluster | Nodes Ready | Kubernetes metrics | EKS integration |
| Cluster | Pods Running/Pending | kube-state-metrics | EKS integration |
| Cluster | Pod Restarts | kube-state-metrics | EKS integration |
| Deployments | Desired vs Available replicas | kube-state-metrics | EKS integration |
| Workloads | CPU by service/pod | Prometheus | EKS integration |
| Workloads | Memory by service/pod | Prometheus | EKS integration |
| Application | Request rate | Application telemetry | Integration pending |
| Application | HTTP error rate | Application telemetry | Integration pending |
| Application | p50/p95/p99 latency | Application telemetry/APM | Integration pending |
| Logs | Structured application logs | Alloy / Loki | Validated |
| Logs | Errors by service | Loki | Validated |
| Logs | Live application logs | Loki | Validated |
| auth-service | Structured logging | Application stdout | Implemented |
| flag-service | Structured logging | Application stdout | Implemented |
| targeting-service | Structured logging | Application stdout | Implemented |
| evaluation-service | Structured logging | Application stdout | Implemented |
| analytics-service | Structured logging | Application stdout | Implemented |
| Tracing | Distributed trace | OpenTelemetry / APM | Separate workstream |
| Tracing | Service Map | Datadog or New Relic | Separate workstream |
| Dependencies | PostgreSQL/RDS | AWS/application metrics | AWS integration |
| Dependencies | Redis | AWS/application metrics | AWS integration |
| Dependencies | SQS | AWS metrics | AWS integration |
| Dependencies | DynamoDB | AWS metrics | AWS integration |
