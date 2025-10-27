import os
import psycopg2
from psycopg2.pool import SimpleConnectionPool

DB_HOST = os.getenv('DB_HOST', 'db')
DB_PORT = int(os.getenv('DB_PORT', '5432'))
DB_USER = os.getenv('DB_USER', 'cinema')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'cinema')
DB_NAME = os.getenv('DB_NAME', 'cinema')

pool = SimpleConnectionPool(
    minconn=1,
    maxconn=10,
    host=DB_HOST,
    port=DB_PORT,
    user=DB_USER,
    password=DB_PASSWORD,
    dbname=DB_NAME,
)

def fetchall(query, params=None):
    conn = pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params or ())
            cols = [d[0] for d in cur.description]
            return [dict(zip(cols, row)) for row in cur.fetchall()]
    finally:
        pool.putconn(conn)

def execute(query, params=None, returning=False):
    conn = pool.getconn()
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(query, params or ())
                if returning:
                    row = cur.fetchone()
                    cols = [d[0] for d in cur.description]
                    return dict(zip(cols, row))
    finally:
        pool.putconn(conn)
