from flask import Flask, render_template, request, redirect, url_for
import sqlite3, os

app = Flask(__name__)
DB_PATH = os.path.join(os.path.dirname(__file__), 'cine.db')

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
def index():
    conn = get_db()
    movies = conn.execute("SELECT * FROM peliculas").fetchall()
    conn.close()
    return render_template('index.html', movies=movies)

@app.route('/movie/<int:movie_id>')
def movie(movie_id):
    conn = get_db()
    movie = conn.execute("SELECT * FROM peliculas WHERE id=?", (movie_id,)).fetchone()
    funciones = conn.execute("SELECT * FROM funciones WHERE pelicula_id=?", (movie_id,)).fetchall()
    conn.close()
    return render_template('movie.html', movie=movie, funciones=funciones)

@app.route('/checkout/<int:funcion_id>', methods=['GET', 'POST'])
def checkout(funcion_id):
    conn = get_db()
    funcion = conn.execute("SELECT f.*, p.titulo FROM funciones f JOIN peliculas p ON f.pelicula_id = p.id WHERE f.id=?", (funcion_id,)).fetchone()
    if request.method == 'POST':
        qty = int(request.form['cantidad'])
        stock = funcion['stock']
        if qty <= 0 or qty > stock:
            return render_template('checkout.html', funcion=funcion, error="Cantidad no válida.")
        new_stock = stock - qty
        conn.execute("UPDATE funciones SET stock=? WHERE id=?", (new_stock, funcion_id))
        conn.commit()
        conn.close()
        return redirect(url_for('confirm', titulo=funcion['titulo'], qty=qty))
    conn.close()
    return render_template('checkout.html', funcion=funcion)

@app.route('/confirm')
def confirm():
    titulo = request.args.get('titulo')
    qty = request.args.get('qty')
    return render_template('confirm.html', titulo=titulo, qty=qty)

@app.route('/health')
def health():
    return {"ok": True}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
