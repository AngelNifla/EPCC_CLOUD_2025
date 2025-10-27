FROM python:3.11-slim
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py ./
COPY templates ./templates
COPY static ./static
EXPOSE 8080
CMD ["gunicorn", "-w", "3", "-b", "0.0.0.0:8080", "app:app"]