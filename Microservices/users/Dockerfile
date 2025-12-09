FROM python:3.11-slim

WORKDIR /app

# Install system dependencies and PostgreSQL client
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    postgresql-client

# Copy application files
COPY main.py /app/main.py
COPY models.py /app/models.py
COPY database.py /app/database.py

# Copy wait script
COPY wait-for-postgres.sh /app/wait-for-postgres.sh
RUN chmod +x /app/wait-for-postgres.sh

# Install Python dependencies
RUN pip install --no-cache-dir fastapi uvicorn sqlalchemy psycopg2-binary

CMD ["/app/wait-for-postgres.sh", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
