# Logging standard

Os serviços devem escrever logs estruturados em JSON no stdout/stderr.

## Campos

Obrigatórios:

- timestamp
- level
- service
- environment
- event

Quando aplicável:

- component
- dependency
- status_code
- duration_ms
- request_id
- trace_id
- message

Exemplo:

    {
      "timestamp": "2026-10-21T18:30:00Z",
      "level": "error",
      "service": "evaluation-service",
      "environment": "homolog",
      "event": "dependency_error",
      "dependency": "flag-service",
      "status_code": 503,
      "duration_ms": 842
    }

## Níveis

- INFO: operação normal relevante
- WARN: comportamento anormal sem indisponibilidade
- ERROR: falha em uma operação ou dependência
- CRITICAL: falha que impede o serviço de funcionar

## Eventos

### auth-service

- service_started
- auth_validation_success
- auth_validation_failed
- api_key_created
- database_error
- health_check_failed

### flag-service

- service_started
- flag_created
- flag_updated
- flag_deleted
- auth_dependency_failed
- auth_dependency_timeout
- database_error
- health_check_failed

### targeting-service

- service_started
- rule_created
- rule_updated
- rule_deleted
- auth_dependency_failed
- auth_dependency_timeout
- database_error
- health_check_failed

### evaluation-service

- service_started
- evaluation_success
- evaluation_failed
- cache_hit
- cache_miss
- redis_error
- dependency_error
- sqs_publish_success
- sqs_publish_error
- health_check_failed

### analytics-service

- service_started
- worker_started
- message_received
- message_processed
- message_failed
- sqs_error
- dynamodb_error
- health_check_failed

## Segurança

Não registrar:

- Authorization
- API keys
- MASTER_KEY
- SERVICE_API_KEY
- DATABASE_URL
- credenciais AWS
- senhas
- tokens
- cookies

## Loki

Labels:

- service
- level
- environment
- namespace
- container

Campos de alta cardinalidade, como `request_id`, `trace_id`, `user_id` e `message_id`, permanecem no conteúdo do log e não devem ser usados como labels.

## Ambientes

- local
- lab
- homolog
- production

VPS:

    environment=lab

EKS:

    environment=homolog
