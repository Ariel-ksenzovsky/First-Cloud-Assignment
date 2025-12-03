from flask import Flask
import os
import pyodbc

app = Flask(__name__)

# Read environment variables
SQL_SERVER   = os.getenv("SQL_SERVER")
SQL_DB       = os.getenv("SQL_DB")
SQL_USER     = os.getenv("SQL_USER")
SQL_PASSWORD = os.getenv("SQL_PASSWORD")

# Build connection string
CONN_STR = (
    f"DRIVER={{ODBC Driver 18 for SQL Server}};"
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
        cursor.execute("SELECT DB_NAME();")
        db_name = cursor.fetchone()[0]
        conn.close()

        return f"<h1>Connected to Azure SQL successfully!</h1><p>Database: {db_name}</p>"

    except Exception as e:
        return f"<h1>Database connection error</h1><pre>{str(e)}</pre>"

@app.route("/messages")
def messages():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT TOP 10 * FROM Messages;")
        rows = cursor.fetchall()
        conn.close()

        if not rows:
            return "<h1>No messages found in the database.</h1>"

        html_rows = "<br>".join([f"{row[0]}: {row[1]}" for row in rows])

        return f"<h1>Messages from Azure SQL</h1><p>{html_rows}</p>"

    except Exception as e:
        return f"<h1>Error reading Messages table</h1><pre>{str(e)}</pre>"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
