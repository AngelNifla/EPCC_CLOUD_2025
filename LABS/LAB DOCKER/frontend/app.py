import os
import requests
from flask import Flask, render_template, request, redirect, url_for, flash

app = Flask(__name__)
app.secret_key = "dev"
BACKEND = os.getenv("BACKEND_BASE_URL", "http://backend:8000")

@app.route("/")
def index():
    movies = requests.get(f"{BACKEND}/movies", timeout=5).json()
    screenings = requests.get(f"{BACKEND}/screenings", timeout=5).json()
    tickets = requests.get(f"{BACKEND}/tickets", timeout=5).json()
    return render_template("index.html", movies=movies, screenings=screenings, tickets=tickets)

@app.route("/buy", methods=["POST"])
def buy():
    screening_id = request.form.get("screening_id")
    customer_name = request.form.get("customer_name")
    quantity = request.form.get("quantity", type=int)
    try:
        r = requests.post(f"{BACKEND}/tickets", json={
            "screening_id": int(screening_id),
            "customer_name": customer_name,
            "quantity": int(quantity)
        }, timeout=5)
        if r.status_code != 201:
            flash(" ¡Error al comprar ticket!", "error")
        else:
            flash("Ticket comprado con éxito!!!!!!!!!!", "ok")
    except Exception:
        flash("......No se pudo contactar al backend", "error")
    return redirect(url_for("index"))