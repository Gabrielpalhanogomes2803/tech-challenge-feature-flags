import json
import logging
import os
import sys
from functools import wraps

import psycopg2
import requests
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from psycopg2.extras import Json, RealDictCursor
from psycopg2.pool import SimpleConnectionPool

from logging_config import configure_logging, log_event


configure_logging()
log = logging.getLogger(__name__)

load_dotenv()

app = Flask(__name__)

DATABASE_URL = os.getenv("DATABASE_URL")
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL")

if not DATABASE_URL or not AUTH_SERVICE_URL:
    log_event(
        log,
        logging.CRITICAL,
        "required_configuration_missing",
        component="configuration",
        message="DATABASE_URL and AUTH_SERVICE_URL are required",
    )
    sys.exit(1)

try:
    pool = SimpleConnectionPool(1, 5, dsn=DATABASE_URL)

    log_event(
        log,
        logging.INFO,
        "database_pool_initialized",
        component="database",
        dependency="postgresql",
    )
except psycopg2.OperationalError:
    log_event(
        log,
        logging.CRITICAL,
        "database_connection_failed",
        component="database",
        dependency="postgresql",
        message="failed to initialize PostgreSQL connection pool",
    )
    sys.exit(1)


def require_auth(function):
    @wraps(function)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization")

        if not auth_header:
            log_event(
                log,
                logging.WARNING,
                "auth_dependency_failed",
                component="authentication",
                dependency="auth-service",
                status_code=401,
                message="authorization header missing",
            )
            return jsonify({"error": "Authorization header obrigatório"}), 401

        try:
            response = requests.get(
                f"{AUTH_SERVICE_URL}/validate",
                headers={"Authorization": auth_header},
                timeout=3,
            )

            if response.status_code != 200:
                log_event(
                    log,
                    logging.WARNING,
                    "auth_dependency_failed",
                    component="authentication",
                    dependency="auth-service",
                    status_code=response.status_code,
                    message="API key validation failed",
                )
                return jsonify({"error": "Chave de API inválida"}), 401

        except requests.exceptions.Timeout:
            log_event(
                log,
                logging.ERROR,
                "auth_dependency_timeout",
                component="authentication",
                dependency="auth-service",
                status_code=504,
                message="auth-service request timed out",
            )
            return jsonify(
                {"error": "Serviço de autenticação indisponível (timeout)"}
            ), 504

        except requests.exceptions.RequestException:
            log_event(
                log,
                logging.ERROR,
                "auth_dependency_failed",
                component="authentication",
                dependency="auth-service",
                status_code=503,
                message="auth-service unavailable",
            )
            return jsonify({"error": "Serviço de autenticação indisponível"}), 503

        return function(*args, **kwargs)

    return decorated


@app.route("/health")
def health():
    conn = None

    try:
        conn = pool.getconn()

        with conn.cursor() as cur:
            cur.execute("SELECT 1")

        return jsonify({"status": "ok", "database": "up"})

    except Exception:
        log_event(
            log,
            logging.ERROR,
            "health_check_failed",
            component="database",
            dependency="postgresql",
            status_code=503,
            message="database unavailable",
        )

        return jsonify({"status": "degraded", "database": "down"}), 503

    finally:
        if conn:
            pool.putconn(conn)


@app.route("/live")
def live():
    return jsonify({"status": "ok"})


@app.route("/rules", methods=["POST"])
@require_auth
def create_rule():
    data = request.get_json()

    if not data or "flag_name" not in data or "rules" not in data:
        return jsonify(
            {"error": "'flag_name' e 'rules' (JSON) são obrigatórios"}
        ), 400

    flag_name = data["flag_name"]
    rules_obj = data["rules"]
    is_enabled = data.get("is_enabled", True)

    conn = None
    cur = None

    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute(
            "INSERT INTO targeting_rules "
            "(flag_name, is_enabled, rules, created_at, updated_at) "
            "VALUES (%s, %s, %s, NOW(), NOW()) RETURNING *",
            (flag_name, is_enabled, Json(rules_obj)),
        )

        new_rule = cur.fetchone()
        conn.commit()

        log_event(
            log,
            logging.INFO,
            "rule_created",
            component="database",
            status_code=201,
        )

        return jsonify(new_rule), 201

    except psycopg2.IntegrityError:
        if conn:
            conn.rollback()

        log_event(
            log,
            logging.WARNING,
            "duplicate_rule",
            component="database",
            status_code=409,
            message="targeting rule already exists",
        )

        return jsonify(
            {"error": f"Regra para a flag '{flag_name}' já existe"}
        ), 409

    except Exception:
        if conn:
            conn.rollback()

        log_event(
            log,
            logging.ERROR,
            "database_error",
            component="database",
            dependency="postgresql",
            status_code=500,
            message="failed to create targeting rule",
        )

        return jsonify({"error": "Erro interno do servidor"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route("/rules/<string:flag_name>", methods=["GET"])
@require_auth
def get_rule(flag_name):
    conn = None
    cur = None

    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute(
            "SELECT * FROM targeting_rules WHERE flag_name = %s",
            (flag_name,),
        )

        rule = cur.fetchone()

        if not rule:
            return jsonify({"error": "Regra não encontrada"}), 404

        return jsonify(rule)

    except Exception:
        log_event(
            log,
            logging.ERROR,
            "database_error",
            component="database",
            dependency="postgresql",
            status_code=500,
            message="failed to get targeting rule",
        )

        return jsonify({"error": "Erro interno do servidor"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route("/rules/<string:flag_name>", methods=["PUT"])
@require_auth
def update_rule(flag_name):
    data = request.get_json()

    if not data:
        return jsonify({"error": "Corpo da requisição obrigatório"}), 400

    fields = []
    values = []

    if "rules" in data:
        fields.append("rules = %s")
        values.append(Json(data["rules"]))

    if "is_enabled" in data:
        fields.append("is_enabled = %s")
        values.append(data["is_enabled"])

    if not fields:
        return jsonify(
            {"error": "Pelo menos um campo ('rules', 'is_enabled') é obrigatório"}
        ), 400

    values.append(flag_name)

    query = (
        f"UPDATE targeting_rules SET {', '.join(fields)} "
        "WHERE flag_name = %s RETURNING *"
    )

    conn = None
    cur = None

    try:
        conn = pool.getconn()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        cur.execute(query, tuple(values))

        if cur.rowcount == 0:
            return jsonify({"error": "Regra não encontrada"}), 404

        updated_rule = cur.fetchone()
        conn.commit()

        log_event(
            log,
            logging.INFO,
            "rule_updated",
            component="database",
            status_code=200,
        )

        return jsonify(updated_rule), 200

    except Exception:
        if conn:
            conn.rollback()

        log_event(
            log,
            logging.ERROR,
            "database_error",
            component="database",
            dependency="postgresql",
            status_code=500,
            message="failed to update targeting rule",
        )

        return jsonify({"error": "Erro interno do servidor"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


@app.route("/rules/<string:flag_name>", methods=["DELETE"])
@require_auth
def delete_rule(flag_name):
    conn = None
    cur = None

    try:
        conn = pool.getconn()
        cur = conn.cursor()

        cur.execute(
            "DELETE FROM targeting_rules WHERE flag_name = %s",
            (flag_name,),
        )

        if cur.rowcount == 0:
            return jsonify({"error": "Regra não encontrada"}), 404

        conn.commit()

        log_event(
            log,
            logging.INFO,
            "rule_deleted",
            component="database",
            status_code=204,
        )

        return "", 204

    except Exception:
        if conn:
            conn.rollback()

        log_event(
            log,
            logging.ERROR,
            "database_error",
            component="database",
            dependency="postgresql",
            status_code=500,
            message="failed to delete targeting rule",
        )

        return jsonify({"error": "Erro interno do servidor"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            pool.putconn(conn)


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8003))

    log_event(
        log,
        logging.INFO,
        "service_started",
        component="http-server",
    )

    app.run(host="0.0.0.0", port=port, debug=False)
