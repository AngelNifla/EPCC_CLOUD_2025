from fastapi import FastAPI
from db import fetchall

app = FastAPI(title='Screenings Service')

@app.get('/health')
def health():
    return {'ok': True}

@app.get('/screenings')
def list_screenings():
    return fetchall('SELECT id, movie_id, show_time, price FROM screenings ORDER BY show_time')
