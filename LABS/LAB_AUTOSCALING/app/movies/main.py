from fastapi import FastAPI
from db import fetchall

app = FastAPI(title='Movies Service')

@app.get('/health')
def health():
    return {'ok': True}

@app.get('/movies')
def list_movies():
    return fetchall('SELECT id, title, description, duration_minutes FROM movies ORDER BY id')
