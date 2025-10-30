import sqlite3, os

DB_PATH = os.path.join(os.path.dirname(__file__), 'cine.db')
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

c.execute("""
CREATE TABLE peliculas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titulo TEXT,
    descripcion TEXT,
    poster TEXT
)
""")

c.execute("""
CREATE TABLE funciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pelicula_id INTEGER,
    fecha TEXT,
    hora TEXT,
    sala TEXT,
    stock INTEGER,
    FOREIGN KEY (pelicula_id) REFERENCES peliculas (id)
)
""")

peliculas = [
    ("Interstellar", "Viaje a través del espacio y el tiempo.", "interstellar.jpg"),
    ("Oppenheimer", "El padre de la bomba atómica.", "oppenheimer.jpg"),
    ("Inception", "El sueño dentro del sueño.", "inception.jpg"),
    ("Avatar 2", "El regreso a Pandora.", "avatar2.jpg"),
    ("Dune 2", "La épica continuación del universo de Dune.", "dune2.jpg")
]

c.executemany("INSERT INTO peliculas (titulo, descripcion, poster) VALUES (?, ?, ?)", peliculas)

funciones = [
    (1, "2025-10-29", "18:00", "Sala 1", 20),
    (1, "2025-10-30", "21:00", "Sala 2", 15),
    (2, "2025-10-29", "19:00", "Sala 1", 25),
    (2, "2025-10-30", "22:00", "Sala 3", 10),
    (3, "2025-10-29", "20:00", "Sala 4", 18),
    (4, "2025-10-29", "17:30", "Sala 2", 12),
    (4, "2025-10-30", "20:30", "Sala 1", 14),
    (5, "2025-10-30", "19:45", "Sala 5", 30)
]

c.executemany("INSERT INTO funciones (pelicula_id, fecha, hora, sala, stock) VALUES (?, ?, ?, ?, ?)", funciones)
conn.commit()
conn.close()

print("Base de datos creada con datos iniciales.")
