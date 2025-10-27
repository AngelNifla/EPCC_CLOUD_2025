import os
import requests
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel

MOVIES_URL = os.getenv('MOVIES_URL', 'http://movies:8000')
SCREENINGS_URL = os.getenv('SCREENINGS_URL', 'http://screenings:8000')
TICKETS_URL = os.getenv('TICKETS_URL', 'http://tickets:8000')

class TicketIn(BaseModel):
    screening_id: int
    customer_name: str
    quantity: int

app = FastAPI(title='Cinema BFF (API Gateway)')

def _get(path, base):
    r = requests.get(f'{base}{path}', timeout=5)
    r.raise_for_status()
    return r.json()

@app.get('/health')
def health():
    return {'ok': True}

@app.get('/movies')
def movies():
    return _get('/movies', MOVIES_URL)

@app.get('/screenings')
def screenings():
    scr = _get('/screenings', SCREENINGS_URL)
    movies = {m['id']: m['title'] for m in _get('/movies', MOVIES_URL)}
    result = []
    for s in scr:
        result.append({
            'id': s['id'],
            'movie': movies.get(s['movie_id'], f"movie:{s['movie_id']}"),
            'show_time': s['show_time'],
            'price': s['price'],
        })
    return result

@app.get('/tickets')
def tickets():
    tks = _get('/tickets', TICKETS_URL)
    scr = {s['id']: s for s in _get('/screenings', SCREENINGS_URL)}
    movies = {m['id']: m for m in _get('/movies', MOVIES_URL)}
    enriched = []
    for t in tks:
        s = scr.get(t['screening_id'])
        if not s:
            enriched.append(t)
            continue
        m = movies.get(s['movie_id'], {})
        enriched.append({
            'id': t['id'],
            'customer_name': t['customer_name'],
            'quantity': t['quantity'],
            'movie': m.get('title', f"movie:{s['movie_id']}"),
            'show_time': s['show_time'],
            'price': s['price'],
            'purchased_at': t['purchased_at'],
        })
    return enriched

@app.post('/tickets', status_code=201)
def create_ticket(ticket: TicketIn):
    try:
        r = requests.post(f'{TICKETS_URL}/tickets', json=ticket.dict(), timeout=5)
        return JSONResponse(status_code=r.status_code, content=r.json())
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail='No se pudo contactar al servicio de tickets') from e
