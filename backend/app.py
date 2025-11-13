from flask import Flask, jsonify, request, Response
from prometheus_client import Counter, Histogram, generate_latest
import psycopg2
import time
import os

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    "flask_request_count", "App Request Count", ["method", "endpoint", "status"]
)
REQUEST_DURATION = Histogram(
    "flask_request_duration_seconds", "Request Duration", ["method", "endpoint"]
)


@app.before_request
def before_request():
    request.start_time = time.time()


@app.after_request
def after_request(response):
    request_duration = time.time() - request.start_time
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    REQUEST_DURATION.labels(request.method, request.path).observe(request_duration)
    return response


def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )


@app.route("/")
def index():
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("INSERT INTO visits DEFAULT VALUES")
        conn.commit()

        cur.execute("SELECT COUNT(*) FROM visits")
        count = cur.fetchone()[0]

        cur.close()
        conn.close()

        return jsonify({"message": "Hello World!", "visits": count})
    except Exception as e:
        return jsonify({"status": "error", "error": str(e)}), 500


# Liveness
@app.route("/alive")
def alive():
    return jsonify({"status": "alive"}), 200


# Readiness
@app.route("/health")
def health():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        conn.close()
        return jsonify({"status": "healthy"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype="text/plain")


if __name__ == "__main__":
    # app.run(host="0.0.0.0", port=5000, debug=True)
    pass
