FROM postgres:16-alpine
ENV POSTGRES_USER=cinema
ENV POSTGRES_PASSWORD=cinema
ENV POSTGRES_DB=cinema
COPY init.sql /docker-entrypoint-initdb.d/init.sql
EXPOSE 5432