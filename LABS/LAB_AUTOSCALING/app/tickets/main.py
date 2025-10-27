from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from db import fetchall, execute

app = FastAPI(title='Tickets Service')

class TicketIn(BaseModel):
    screening_id: int
    customer_name: str
    quantity: int

@app.get('/health')
def health():
    return {'ok': True}

@app.get('/tickets')
def list_tickets():
    return fetchall('SELECT id, screening_id, customer_name, quantity, purchased_at FROM tickets ORDER BY purchased_at DESC')

@app.post('/tickets', status_code=201)
def create_ticket(ticket: TicketIn):
    if ticket.quantity <= 0:
        raise HTTPException(status_code=400, detail='quantity debe ser > 0')
    row = execute(
        'INSERT INTO tickets (screening_id, customer_name, quantity)\n'
        'VALUES (%s, %s, %s)\n'
        'RETURNING id, screening_id, customer_name, quantity, purchased_at',
        (ticket.screening_id, ticket.customer_name, ticket.quantity),
        returning=True,
    )
    if not row:
        raise HTTPException(status_code=500, detail='No se pudo crear ticket')
    return row
