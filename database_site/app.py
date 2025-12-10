from flask import Flask, jsonify
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
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT TOP 1 1;")
        row = cursor.fetchone()
        return f"DB OK, SELECT 1 returned: {row[0]}"
    except Exception as e:
        # show error for debugging
        return f"Database connection error: {repr(e)}", 500
    
@app.route("/messages")
def messages():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT TOP 50 messagesText FROM Messages;")
        rows = cursor.fetchall()
        msgs = [r[0] for r in rows]
        return jsonify(messages=msgs)
    except Exception as e:
        return f"Error reading Messages table: {repr(e)}", 500

if __name__ == "__main__":
    # listen on all interfaces, port 8080
    app.run(host="0.0.0.0", port=8080)
