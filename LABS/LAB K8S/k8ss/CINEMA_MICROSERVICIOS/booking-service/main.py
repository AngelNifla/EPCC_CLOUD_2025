
from fastapi import FastAPI, HTTPException
import os
import psycopg2
import psycopg2.extras

DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_USER = os.getenv("DB_USER", "booking_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "cinema")
DB_NAME = os.getenv("DB_NAME", "cinema")

def conn():
    return psycopg2.connect(host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASSWORD, dbname=DB_NAME)

app = FastAPI(title="booking-service")

@app.get("/health")
def health():
    try:
        with conn() as c:
            with c.cursor() as cur:
                cur.execute("SELECT 1;")
        return {"status":"ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/tickets")
def list_items():
    try:
        with conn() as c:
            with c.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute("""SELECT id, screening_id, seat, buyer FROM tickets ORDER BY id;""" )
                rows = cur.fetchall()
        return rows
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


from pydantic import BaseModel

class TicketIn(BaseModel):
    screening_id: int
    seat: str
    buyer: str

@app.post("/tickets")
def create_ticket(ticket: TicketIn):
    try:
        with conn() as c:
            with c.cursor() as cur:
                cur.execute("""INSERT INTO tickets (screening_id, seat, buyer) VALUES (%s, %s, %s) RETURNING id;""", (ticket.screening_id, ticket.seat, ticket.buyer))
                new_id = cur.fetchone()[0]
                c.commit()
        return {"id": new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
