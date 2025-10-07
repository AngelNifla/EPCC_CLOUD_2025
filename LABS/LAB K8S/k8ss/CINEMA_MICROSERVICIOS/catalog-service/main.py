
from fastapi import FastAPI, HTTPException
import os
import psycopg2
import psycopg2.extras

DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_USER = os.getenv("DB_USER", "catalog_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "cinema")
DB_NAME = os.getenv("DB_NAME", "cinema")

def conn():
    return psycopg2.connect(host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASSWORD, dbname=DB_NAME)

app = FastAPI(title="catalog-service")

@app.get("/health")
def health():
    try:
        with conn() as c:
            with c.cursor() as cur:
                cur.execute("SELECT 1;")
        return {"status":"ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/movies")
def list_items():
    try:
        with conn() as c:
            with c.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("""SELECT id, title, genre, year FROM movies ORDER BY id;""" )
                rows = cur.fetchall()
        return rows
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
