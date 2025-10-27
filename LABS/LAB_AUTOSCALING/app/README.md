# Cinema Microservices (Local Docker)

Esta carpeta contiene una adaptación **mínima** de la app Cinema a una arquitectura de **microservicios** (movies, screenings, tickets) más un **BFF/API Gateway** que mantiene los endpoints actuales consumidos por el frontend.

## Servicios
- `db` (PostgreSQL): Base de datos con `init.sql`.
- `movies` (FastAPI): Películas → `GET /movies`.
- `screenings` (FastAPI): Funciones/horarios → `GET /screenings`.
- `tickets` (FastAPI): Tickets → `GET /tickets`, `POST /tickets`.
- `backend` (BFF FastAPI): expone **la misma API** que el monolito: `GET /movies`, `GET /screenings`, `GET /tickets`, `POST /tickets` agregando datos desde los microservicios.
- `frontend` (Flask): UI sin cambios, apunta a `BACKEND_BASE_URL=http://backend:8000`.

## Ejecutar (local)
```bash
docker compose -f docker-compose.micro.yml up --build
```

- Frontend: http://localhost:8080
- API BFF (docs): http://localhost:8000/docs

## Notas técnicas
- Para simplificar, todos los microservicios comparten la **misma BD** (tablas ya existentes). En producción podrías separar esquemas/BD por servicio.
- El BFF agrega campos esperados por el frontend (por ejemplo, `movie`, `show_time`, `price` dentro de `/tickets`).
- El código de cada microservicio es mínimo y se basa en las consultas del monolito. Puedes extender con CRUDs completos, validaciones, etc.
- El `POST /tickets` devuelve **201**, tal como espera el frontend.
