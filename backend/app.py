from flask import Flask, jsonify, request, Response, render_template, redirect, session
from prometheus_client import Counter, Histogram, generate_latest
import psycopg2
import psycopg2.extras
from psycopg2 import pool
import time
import os
import atexit
import secrets

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", secrets.token_hex(32))

REQUEST_COUNT = Counter(
    "flask_request_count", "App Request Count", ["method", "endpoint", "status"]
)
REQUEST_DURATION = Histogram(
    "flask_request_duration_seconds", "Request Duration", ["method", "endpoint"]
)

connection_pool = None

def init_pool():
    global connection_pool
    connection_pool = psycopg2.pool.SimpleConnectionPool(
        minconn=1,
        maxconn=10,
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )

def get_db_connection():
    if connection_pool is None:
        init_pool()
    return connection_pool.getconn()

def return_db_connection(conn):
    if connection_pool:
        connection_pool.putconn(conn)

def close_pool():
    if connection_pool:
        connection_pool.closeall()

init_pool()
atexit.register(close_pool)


@app.before_request
def before_request():
    request.start_time = time.time()
    # Set default workspace if not set
    if 'workspace_id' not in session:
        session['workspace_id'] = 'default'


@app.after_request
def after_request(response):
    request_duration = time.time() - request.start_time
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    REQUEST_DURATION.labels(request.method, request.path).observe(request_duration)
    return response


def get_client_ip():
    return request.headers.get("X-Forwarded-For", request.remote_addr).split(",")[0]


def get_workspace_id():
    return session.get('workspace_id', 'default')


@app.route("/workspace")
def workspace_selector():
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT DISTINCT workspace_id FROM polls ORDER BY workspace_id")
        workspaces = [row['workspace_id'] for row in cur.fetchall()]
        cur.close()
        
        current = get_workspace_id()
        return render_template("workspace.html", workspaces=workspaces, current=current)
    finally:
        return_db_connection(conn)


@app.route("/workspace/set", methods=["POST"])
def set_workspace():
    workspace_id = request.form.get("workspace_id", "").strip()
    if workspace_id:
        session['workspace_id'] = workspace_id
    return redirect("/")


@app.route("/")
def index():
    workspace_id = get_workspace_id()
    conn = get_db_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cur.execute(
            """
            SELECT p.id, p.title, p.created_at, p.expires_at,
                   COUNT(DISTINCT v.id) as total_votes
            FROM polls p
            LEFT JOIN votes v ON p.id = v.poll_id
            WHERE p.workspace_id = %s 
              AND (p.expires_at IS NULL OR p.expires_at > NOW())
            GROUP BY p.id
            ORDER BY p.created_at DESC
        """,
            (workspace_id,)
        )
        polls = cur.fetchall()
        cur.close()

        return render_template("index.html", polls=polls, workspace=workspace_id)
    finally:
        return_db_connection(conn)


@app.route("/create", methods=["GET", "POST"])
def create_poll():
    workspace_id = get_workspace_id()
    
    if request.method == "POST":
        title = request.form.get("title")
        options = [v for k, v in request.form.items() if k.startswith("option_") and v]
        expires_hours = request.form.get("expires_hours")

        if not title or len(options) < 2:
            return render_template(
                "create.html", error="Title and at least 2 options required", workspace=workspace_id
            )

        conn = get_db_connection()
        try:
            cur = conn.cursor()

            expires_at = None
            if expires_hours:
                cur.execute("SELECT NOW() + INTERVAL '%s hours'", (expires_hours,))
                expires_at = cur.fetchone()[0]

            cur.execute(
                "INSERT INTO polls (title, workspace_id, expires_at) VALUES (%s, %s, %s) RETURNING id",
                (title, workspace_id, expires_at),
            )
            poll_id = cur.fetchone()[0]

            for option in options:
                cur.execute(
                    "INSERT INTO options (poll_id, text) VALUES (%s, %s)", (poll_id, option)
                )

            conn.commit()
            cur.close()

            return redirect(f"/poll/{poll_id}")
        except Exception as e:
            conn.rollback()
            raise
        finally:
            return_db_connection(conn)

    return render_template("create.html", workspace=workspace_id)


@app.route("/poll/<int:poll_id>", methods=["GET", "POST"])
def view_poll(poll_id):
    workspace_id = get_workspace_id()
    conn = get_db_connection()
    try:
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
            """SELECT * FROM polls 
               WHERE id = %s 
                 AND workspace_id = %s 
                 AND (expires_at IS NULL OR expires_at > NOW())""",
            (poll_id, workspace_id),
        )
        poll = cur.fetchone()

        if not poll:
            cur.close()
            return "Poll not found or access denied", 404

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

        return render_template(
            "poll.html",
            poll=poll,
            options=options,
            total_votes=total_votes,
            has_voted=has_voted,
            workspace=workspace_id,
        )
    finally:
        return_db_connection(conn)


@app.route("/alive")
def alive():
    return jsonify({"status": "alive"}), 200


@app.route("/health")
def health():
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT 1")
        cur.close()
        return jsonify({"status": "healthy"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500
    finally:
        return_db_connection(conn)


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype="text/plain")


if __name__ == "__main__":
    pass
