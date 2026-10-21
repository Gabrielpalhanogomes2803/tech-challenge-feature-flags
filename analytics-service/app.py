import json
import logging
import os
import sys
import threading
import time
import uuid

import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from dotenv import load_dotenv
from flask import Flask, jsonify

from logging_config import configure_logging, log_event


configure_logging()
log = logging.getLogger(__name__)

load_dotenv()

AWS_REGION = os.getenv("AWS_REGION")
SQS_QUEUE_URL = os.getenv("AWS_SQS_URL")
DYNAMODB_TABLE_NAME = os.getenv("AWS_DYNAMODB_TABLE")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")

if not all([AWS_REGION, SQS_QUEUE_URL, DYNAMODB_TABLE_NAME]):
    log_event(
        log,
        logging.CRITICAL,
        "required_configuration_missing",
        component="configuration",
        message="AWS_REGION, AWS_SQS_URL and AWS_DYNAMODB_TABLE are required",
    )
    sys.exit(1)

try:
    session = boto3.Session(region_name=AWS_REGION)

    sqs_client = session.client(
        "sqs",
        endpoint_url=AWS_ENDPOINT_URL,
    )

    dynamodb_client = session.client(
        "dynamodb",
        endpoint_url=AWS_ENDPOINT_URL,
    )

    log_event(
        log,
        logging.INFO,
        "aws_clients_initialized",
        component="aws",
    )

except NoCredentialsError:
    log_event(
        log,
        logging.CRITICAL,
        "aws_credentials_missing",
        component="aws",
        message="AWS credentials not available",
    )
    sys.exit(1)

except Exception:
    log_event(
        log,
        logging.CRITICAL,
        "aws_client_initialization_failed",
        component="aws",
        message="failed to initialize AWS clients",
    )
    sys.exit(1)


def process_message(message):
    message_id = message.get("MessageId")

    log_event(
        log,
        logging.INFO,
        "message_received",
        component="queue",
        dependency="sqs",
    )

    try:
        body = json.loads(message["Body"])

        event_id = str(uuid.uuid4())

        item = {
            "event_id": {"S": event_id},
            "user_id": {"S": body["user_id"]},
            "flag_name": {"S": body["flag_name"]},
            "result": {"BOOL": body["result"]},
            "timestamp": {"S": body["timestamp"]},
        }

        dynamodb_client.put_item(
            TableName=DYNAMODB_TABLE_NAME,
            Item=item,
        )

        sqs_client.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=message["ReceiptHandle"],
        )

        log_event(
            log,
            logging.INFO,
            "message_processed",
            component="worker",
            dependency="dynamodb",
        )

    except json.JSONDecodeError:
        log_event(
            log,
            logging.ERROR,
            "message_failed",
            component="worker",
            dependency="sqs",
            message="invalid JSON message",
        )

    except ClientError:
        log_event(
            log,
            logging.ERROR,
            "message_failed",
            component="worker",
            message="AWS operation failed while processing message",
        )

    except Exception:
        log_event(
            log,
            logging.ERROR,
            "message_failed",
            component="worker",
            message="unexpected error while processing message",
        )


def sqs_worker_loop():
    log_event(
        log,
        logging.INFO,
        "worker_started",
        component="worker",
        dependency="sqs",
    )

    while True:
        try:
            response = sqs_client.receive_message(
                QueueUrl=SQS_QUEUE_URL,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20,
            )

            messages = response.get("Messages", [])

            for message in messages:
                process_message(message)

        except ClientError:
            log_event(
                log,
                logging.ERROR,
                "sqs_error",
                component="queue",
                dependency="sqs",
                message="SQS receive operation failed",
            )

            time.sleep(10)

        except Exception:
            log_event(
                log,
                logging.ERROR,
                "sqs_error",
                component="queue",
                dependency="sqs",
                message="unexpected SQS worker error",
            )

            time.sleep(10)


app = Flask(__name__)


@app.route("/health")
def health():
    try:
        dynamodb_client.describe_table(
            TableName=DYNAMODB_TABLE_NAME
        )

        sqs_client.get_queue_attributes(
            QueueUrl=SQS_QUEUE_URL,
            AttributeNames=["QueueArn"],
        )

        return jsonify({"status": "ok"})

    except ClientError:
        log_event(
            log,
            logging.ERROR,
            "health_check_failed",
            component="aws",
            status_code=503,
            message="SQS or DynamoDB dependency unavailable",
        )

        return jsonify({"status": "degraded"}), 503


@app.route("/live")
def live():
    return jsonify({"status": "ok"})


def start_worker():
    worker_thread = threading.Thread(
        target=sqs_worker_loop,
        daemon=True,
    )
    worker_thread.start()


start_worker()

log_event(
    log,
    logging.INFO,
    "service_started",
    component="http-server",
)

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8005))
    app.run(
        host="0.0.0.0",
        port=port,
        debug=False,
    )
