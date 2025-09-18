# CinemAQP con Docker (Frontend + Backend + DB)

## 1. Introducción
En este proyecto utilicé **Docker** para crear una aplicación web de venta de tickets de cine. 
La aplicación se compone de **tres contenedores**:
- **Frontend** (Flask + Gunicorn) → interfaz web.
- **Backend** (FastAPI + Uvicorn) → API REST.
- **Base de datos** (PostgreSQL 16) → almacenamiento de películas, funciones y tickets.

Docker permite aislar cada componente en su propio contenedor y **Docker Compose** los orquesta para que trabajen juntos.

---

## 2. Conceptos básicos

- **Docker** → plataforma para empaquetar aplicaciones con sus dependencias. 
- **Contenedor** → instancia aislada de una aplicación (cada servicio corre en uno). 
- **Orquestador (Docker Compose)** → coordina varios contenedores, crea una red interna y administra variables, puertos y dependencias.

---

## 3. ¿Qué información debe ir en un Dockerfile?

Un Dockerfile es la **receta de construcción de una imagen**. 
Normalmente incluye:

1. **Imagen base** (ej: `python:3.11-slim`, `postgres:16-alpine`).
2. **Dependencias del sistema y del lenguaje** (instalación con `pip`, `apt-get`, etc.).
3. **Archivos de la aplicación** (código, plantillas HTML, SQL).
4. **Variables de entorno** necesarias en la configuración.
5. **Puertos expuestos** (ej: `EXPOSE 8080`).
6. **Comando de arranque** (ej: `CMD ["uvicorn", ...]`).

---

## 4. Configuración de los contenedores

### 4.1 `docker-compose.yml`
Define y organiza los 3 servicios. 
- Crea contenedores separados: `db`, `backend`, `frontend`.
- Conecta los servicios en una **red interna** (se comunican por nombre).
- Establece **variables de entorno**, **puertos expuestos** y **orden de arranque**.

### 4.2 Flujo

- Compose construye las imágenes y crea los contenedores.

- Los conecta en una red interna.

- Orden de arranque:

 Primero db (Postgres).

 Luego backend (espera al healthcheck de la DB).

 Finalmente frontend.

- Servicios disponibles:

Frontend → http://localhost:8080

Backend (Swagger UI) → http://localhost:8000/docs

BD (psql desde host) → psql -h localhost -U cinema -d cinema

