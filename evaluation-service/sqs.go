package main

import (
	"encoding/json"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/sqs"
)

type EvaluationEvent struct {
	UserID    string    `json:"user_id"`
	FlagName  string    `json:"flag_name"`
	Result    bool      `json:"result"`
	Timestamp time.Time `json:"timestamp"`
}

func (a *App) sendEvaluationEvent(userID, flagName string, result bool) {
	if a.SqsSvc == nil || a.SqsQueueURL == "" {
		writeLog("warn", "sqs_disabled", LogEvent{
			Component:  "queue",
			Dependency: "sqs",
			Message:    "SQS is not configured",
		})
		return
	}

	event := EvaluationEvent{
		UserID:    userID,
		FlagName:  flagName,
		Result:    result,
		Timestamp: time.Now().UTC(),
	}

	body, err := json.Marshal(event)
	if err != nil {
		writeLog("error", "sqs_publish_error", LogEvent{
			Component:  "queue",
			Dependency: "sqs",
			Message:    "failed to encode evaluation event",
		})
		return
	}

	_, err = a.SqsSvc.SendMessage(&sqs.SendMessageInput{
		MessageBody: aws.String(string(body)),
		QueueUrl:    aws.String(a.SqsQueueURL),
	})

	if err != nil {
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
