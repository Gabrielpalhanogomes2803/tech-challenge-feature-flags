FROM golang:1.24 AS builder

WORKDIR /app

COPY . .

RUN go mod tidy
RUN go build -o evaluation-service .

FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/evaluation-service .

CMD ["./evaluation-service"]
