# Usa una imagen base de Python
FROM python:3.9-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar los archivos del proyecto a /app en el contenedor
COPY . /app

# Instalar las dependencias de la app desde el requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Ejecutar el script de inicialización de la base de datos antes de iniciar la app
RUN python app/db_init.py


# Exponer el puerto 5000 para la app Flask
EXPOSE 5000

# Comando para ejecutar la app con gunicorn (4 workers)
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app.app:app"]

