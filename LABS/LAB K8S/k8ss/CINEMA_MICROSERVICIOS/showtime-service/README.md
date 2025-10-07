
# Cinema Microservices
Servicios FastAPI:
- catalog-service  → GET /movies
- showtime-service → GET /screenings
- booking-service  → GET /tickets, POST /tickets

## Build & Push
```bash
export DOCKER_USER=tu_usuario
export TAG=1.0.0
./build_and_push_microservices.sh
```
