FROM python:3.11-slim

WORKDIR /app

# Installer dépendances système requises pour psycopg2-binary
RUN apt-get update && apt-get install -y gcc libpq-dev

COPY . .

RUN pip install --no-cache-dir fastapi uvicorn sqlalchemy psycopg2-binary

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
