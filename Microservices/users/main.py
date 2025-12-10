from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

Instrumentator().instrument(app).expose(app, endpoint="/users/metrics")

@app.get("/users")
def list_users():
    return {"users": ["alice", "bob", "charlie"]}
