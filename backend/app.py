from flask import Flask, jsonify, request
import psycopg2
import time
import os

app = Flask(__name__)


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


@app.route("/stress")
def stress():
    """CPU stress endpoint for testing HPA"""
    duration = int(request.args.get('duration', 30))  # seconds
    start = time.time()
    
    # Busy loop to consume CPU
    while time.time() - start < duration:
        _ = sum(i * i for i in range(10000))
    
    return jsonify({
        "status": "completed",
        "duration": duration,
        "message": "CPU stress test finished"
    })


if __name__ == "__main__":
    # app.run(host="0.0.0.0", port=5000, debug=True)
    pass
