from flask import Flask, jsonify, request, Response, render_template, redirect
from prometheus_client import Counter, Histogram, generate_latest
import psycopg2
import time
import os

app = Flask(__name__)

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


def get_client_ip():
    return request.headers.get("X-Forwarded-For", request.remote_addr).split(",")[0]


@app.route("/")
def index():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    cur.execute(
        """
        SELECT p.id, p.title, p.created_at, p.expires_at,
               COUNT(DISTINCT v.id) as total_votes
        FROM polls p
        LEFT JOIN votes v ON p.id = v.poll_id
        WHERE p.expires_at IS NULL OR p.expires_at > NOW()
        GROUP BY p.id
        ORDER BY p.created_at DESC
    """
    )
    polls = cur.fetchall()

    cur.close()
    conn.close()

    return render_template("index.html", polls=polls)


@app.route("/create", methods=["GET", "POST"])
def create_poll():
    if request.method == "POST":
        title = request.form.get("title")
        options = [v for k, v in request.form.items() if k.startswith("option_") and v]
        expires_hours = request.form.get("expires_hours")

        if not title or len(options) < 2:
            return render_template(
                "create.html", error="Title and at least 2 options required"
            )

        conn = get_db_connection()
        cur = conn.cursor()

        expires_at = None
        if expires_hours:
            cur.execute("SELECT NOW() + INTERVAL '%s hours'", (expires_hours,))
            expires_at = cur.fetchone()[0]

        cur.execute(
            "INSERT INTO polls (title, expires_at) VALUES (%s, %s) RETURNING id",
            (title, expires_at),
        )
        poll_id = cur.fetchone()[0]

        for option in options:
            cur.execute(
                "INSERT INTO options (poll_id, text) VALUES (%s, %s)", (poll_id, option)
            )

        conn.commit()
        cur.close()
        conn.close()

        return redirect(f"/poll/{poll_id}")

    return render_template("create.html")


@app.route("/poll/<int:poll_id>", methods=["GET", "POST"])
def view_poll(poll_id):
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    if request.method == "POST":
        option_id = request.form.get("option_id")
        voter_ip = get_client_ip()

        try:
            cur.execute(
                "INSERT INTO votes (poll_id, voter_ip) VALUES (%s, %s)",
                (poll_id, voter_ip),
            )
            cur.execute(
                "UPDATE options SET votes = votes + 1 WHERE id = %s AND poll_id = %s",
                (option_id, poll_id),
            )
            conn.commit()
        except psycopg2.IntegrityError:
            conn.rollback()

    cur.execute(
        "SELECT * FROM polls WHERE id = %s AND (expires_at IS NULL OR expires_at > NOW())",
        (poll_id,),
    )
    poll = cur.fetchone()

    if not poll:
        cur.close()
        conn.close()
        return "Poll not found", 404

    cur.execute(
        "SELECT id, text, votes FROM options WHERE poll_id = %s ORDER BY id", (poll_id,)
    )
    options = cur.fetchall()

    cur.execute("SELECT COUNT(*) as total FROM votes WHERE poll_id = %s", (poll_id,))
    total_votes = cur.fetchone()["total"]

    voter_ip = get_client_ip()
    cur.execute(
        "SELECT 1 FROM votes WHERE poll_id = %s AND voter_ip = %s", (poll_id, voter_ip)
    )
    has_voted = cur.fetchone() is not None

    cur.close()
    conn.close()

    return render_template(
        "poll.html",
        poll=poll,
        options=options,
        total_votes=total_votes,
        has_voted=has_voted,
    )


@app.route("/alive")
def alive():
    return jsonify({"status": "alive"}), 200


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
    pass
