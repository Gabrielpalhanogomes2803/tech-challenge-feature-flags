package main

import (
	"context"
	"encoding/json"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
)

type EvaluationEvent struct {
	UserID    string    `json:"user_id"`
	FlagName  string    `json:"flag_name"`
	Result    bool      `json:"result"`
	Timestamp time.Time `json:"timestamp"`
}

func (a *App) sendEvaluationEvent(ctx context.Context, userID, flagName string, result bool) {
	if a.SqsSvc == nil || a.SqsQueueURL == "" {
		writeLog("warn", "sqs_disabled", LogEvent{
			Component:  "queue",
			Dependency: "sqs",
			Message:    "SQS is not configured",
		})
		return
	}

	// Span de producer: é o pai do span "togglemaster-analytics process" no analytics-service.
	ctx, span := otel.Tracer("evaluation-service").Start(ctx, "sqs.send",
		trace.WithSpanKind(trace.SpanKindProducer),
		trace.WithAttributes(
			attribute.String("messaging.system", "aws_sqs"),
			attribute.String("messaging.operation.type", "send"),
		),
	)
	defer span.End()

	event := EvaluationEvent{
		UserID:    userID,
		FlagName:  flagName,
		Result:    result,
		Timestamp: time.Now().UTC(),
	}

	body, err := json.Marshal(event)
	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "failed to encode evaluation event")
		writeLog("error", "sqs_publish_error", LogEvent{
			Component:  "queue",
			Dependency: "sqs",
			Message:    "failed to encode evaluation event",
		})
		return
	}

	// Injeta o traceparent (W3C) nos atributos da mensagem. DataType "String" e
	// chave "traceparent" são o contrato com o analytics-service.
	carrier := propagation.MapCarrier{}
	otel.GetTextMapPropagator().Inject(ctx, carrier)

	attrs := make(map[string]*sqs.MessageAttributeValue, len(carrier))
	for k, v := range carrier {
		attrs[k] = &sqs.MessageAttributeValue{
			DataType:    aws.String("String"),
			StringValue: aws.String(v),
		}
	}

	_, err = a.SqsSvc.SendMessageWithContext(ctx, &sqs.SendMessageInput{
		MessageBody:       aws.String(string(body)),
		QueueUrl:          aws.String(a.SqsQueueURL),
		MessageAttributes: attrs,
	})

	if err != nil {
		span.RecordError(err)
		span.SetStatus(codes.Error, "failed to publish evaluation event")
		writeLog("error", "sqs_publish_error", LogEvent{
			Component:  "queue",
			Dependency: "sqs",
			Message:    "failed to publish evaluation event",
		})
		return
	}

	writeLog("info", "sqs_publish_success", LogEvent{
		Component:  "queue",
		Dependency: "sqs",
	})
}