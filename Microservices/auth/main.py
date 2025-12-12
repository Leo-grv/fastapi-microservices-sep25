from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

# Expose metrics at /auth/metrics
Instrumentator().instrument(app).expose(app, endpoint="/auth/metrics")

@app.get("/auth")
def auth_root():
    return {"message": "Auth service OK"}
