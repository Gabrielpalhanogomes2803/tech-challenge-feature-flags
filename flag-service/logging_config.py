import json
import logging
import os
from datetime import datetime, timezone


SERVICE_NAME = "flag-service"


class JsonFormatter(logging.Formatter):
    def format(self, record):
        data = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname.lower(),
            "service": SERVICE_NAME,
            "environment": os.getenv("ENVIRONMENT", "local"),
            "event": getattr(record, "event", "application_log"),
        }

        for field in (
            "component",
            "dependency",
            "status_code",
            "duration_ms",
            "message_detail",
        ):
            value = getattr(record, field, None)

            if value is not None:
                data[field] = value

        if not getattr(record, "message_detail", None):
            data["message"] = record.getMessage()

        return json.dumps(data, ensure_ascii=False)


def configure_logging():
    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(logging.INFO)


def log_event(logger, level, event, **fields):
    logger.log(
        level,
        fields.pop("message", event),
        extra={
            "event": event,
            **fields,
        },
    )
