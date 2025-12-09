#!/bin/sh

set -e

echo "Waiting for Postgres at host: $POSTGRES_HOST"

until pg_isready -h "$POSTGRES_HOST" -p 5432 > /dev/null 2>&1; do
  echo "Postgres not ready..."
  sleep 1
done

echo "Postgres is ready."

exec "$@"
