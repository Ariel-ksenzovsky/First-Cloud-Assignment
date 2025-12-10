from flask import Flask, jsonify, request
import pyodbc

app = Flask(__name__)

# 🔐 Direct values that we KNOW work (same as test_db.py)
SQL_SERVER   = "dev-cloud-sql-server-01.database.windows.net"
SQL_DB       = "dev-cloud-sqldb"
SQL_USER     = "sqladminuser"
SQL_PASSWORD = "StrongSqlAdminPass123!"  # later you can switch back to env vars

# 👇 Use the SAME DRIVER that worked in test_db.py
CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"  # or 18, if that's what you used
    f"SERVER={SQL_SERVER},1433;"
    f"DATABASE={SQL_DB};"
    f"UID={SQL_USER};"
    f"PWD={SQL_PASSWORD};"
    "Encrypt=yes;"
    "TrustServerCertificate=no;"
    "Connection Timeout=30;"
)

def get_connection():
    return pyodbc.connect(CONN_STR)


@app.route("/")
def index():
    """
    Home page with a simple, nice HTML card that shows DB status.
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT TOP 1 1;")
        row = cursor.fetchone()
        db_ok = True
        msg = f"SELECT 1 returned: {row[0]}"
    except Exception as e:
        db_ok = False
        msg = repr(e)

    status_text = "✅ Database connection OK" if db_ok else "❌ Database connection error"

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Dev Cloud Status</title>
        <meta charset="utf-8" />
        <style>
            body {{
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                margin: 0;
                padding: 40px;
            }}
            .card {{
                background: white;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px 25px;
                border-radius: 10px;
                box-shadow: 0 2px 6px rgba(0,0,0,0.15);
            }}
            h1 {{
                margin-top: 0;
            }}
            .status-ok {{
                color: #2e7d32;
                font-weight: bold;
            }}
            .status-bad {{
                color: #c62828;
                font-weight: bold;
            }}
            .detail {{
                margin-top: 8px;
                font-size: 0.9rem;
                color: #555;
            }}
            a.button {{
                display: inline-block;
                margin-top: 15px;
                padding: 10px 15px;
                background: #1976d2;
                color: #fff;
                text-decoration: none;
                border-radius: 6px;
            }}
            a.button:hover {{
                background: #0d47a1;
            }}
        </style>
    </head>
    <body>
        <div class="card">
            <h1>Dev Cloud Demo</h1>
            <p class="{ 'status-ok' if db_ok else 'status-bad' }">{status_text}</p>
            <p class="detail">{msg}</p>
            <a href="/messages" class="button">View Messages</a>
        </div>
    </body>
    </html>
    """
    return html


@app.route("/messages")
def messages():
    """
    Show messages either as JSON (?format=json) or nice HTML list (default).
    """
    # JSON mode if ?format=json
    if request.args.get("format") == "json":
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT TOP 50 messagesText FROM Messages;")
            rows = cursor.fetchall()
            msgs = [r[0] for r in rows]
            return jsonify(messages=msgs)
        except Exception as e:
            return jsonify(error=repr(e)), 500

    # HTML mode (default)
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT TOP 50 messagesText FROM Messages;")
        rows = cursor.fetchall()
        msgs = [r[0] for r in rows]
        error_msg = None
    except Exception as e:
        msgs = []
        error_msg = repr(e)

    items_html = "".join(f"<li>{m}</li>" for m in msgs) or "<li><em>No messages found</em></li>"

    error_block = ""
    if error_msg:
        error_block = f"""
        <div style="margin-top:10px; color:#c62828;">
            <strong>Error reading Messages table:</strong><br/>
            <code>{error_msg}</code>
        </div>
        """

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Messages</title>
        <meta charset="utf-8" />
        <style>
            body {{
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                margin: 0;
                padding: 40px;
            }}
            .card {{
                background: white;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px 25px;
                border-radius: 10px;
                box-shadow: 0 2px 6px rgba(0,0,0,0.15);
            }}
            h1 {{
                margin-top: 0;
            }}
            ul {{
                padding-left: 20px;
                line-height: 1.6;
            }}
            a {{
                color: #1976d2;
                text-decoration: none;
            }}
            a:hover {{
                text-decoration: underline;
            }}
            .hint {{
                margin-top: 10px;
                font-size: 0.85rem;
                color: #555;
            }}
        </style>
    </head>
    <body>
        <div class="card">
            <h1>Messages</h1>
            <ul>
                {items_html}
            </ul>
            {error_block}
            <p><a href="/">← Back to home</a></p>
            <p class="hint">Need JSON? Open <code>/messages?format=json</code></p>
        </div>
    </body>
    </html>
    """
    return html


if __name__ == "__main__":
    # listen on all interfaces, port 8080
    app.run(host="0.0.0.0", port=8080)
