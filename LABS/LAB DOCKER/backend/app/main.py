from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from .db import fetchall, execute

app = FastAPI(title="Cinema Tickets API")

class TicketIn(BaseModel):
    screening_id: int
    customer_name: str
    quantity: int

@app.get("/health")
def health():
    return {"ok": True}

@app.get("/movies")
def movies():
    return fetchall("SELECT * FROM movies ORDER BY id ASC")

@app.get("/screenings")
def screenings():
    return fetchall(
        '''
        SELECT s.id, s.show_time, s.price, m.title AS movie
        FROM screenings s
        JOIN movies m ON m.id = s.movie_id
        ORDER BY s.show_time ASC
        '''
    )

@app.get("/tickets")
def tickets():
    return fetchall(
        '''
        SELECT t.id, t.customer_name, t.quantity, t.purchased_at,
               s.show_time, s.price, m.title AS movie
        FROM tickets t
        JOIN screenings s ON s.id = t.screening_id
        JOIN movies m ON m.id = s.movie_id
        ORDER BY t.purchased_at DESC
        '''
    )

@app.post("/tickets", status_code=201)
def create_ticket(ticket: TicketIn):
    if ticket.quantity <= 0:
        raise HTTPException(status_code=400, detail="quantity debe ser > 0")
    row = execute(
        '''
        INSERT INTO tickets (screening_id, customer_name, quantity)
        VALUES (%s, %s, %s)
        RETURNING id, screening_id, customer_name, quantity, purchased_at
        ''',
        (ticket.screening_id, ticket.customer_name, ticket.quantity),
        returning=True,
    )
    if not row:
        raise HTTPException(status_code=500, detail="No se pudo crear ticket")
    return row