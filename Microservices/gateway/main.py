from fastapi import FastAPI
import httpx
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

Instrumentator().instrument(app).expose(app, endpoint="/gateway/metrics")

@app.get("/")
def root():
    return {"message": "Gateway OK"}

@app.get("/auth")
async def call_auth():
    async with httpx.AsyncClient() as client:
        return (await client.get("http://auth-service:8000/auth")).json()

@app.get("/users")
async def call_users():
    async with httpx.AsyncClient() as client:
        return (await client.get("http://users-service:8000/users")).json()

@app.get("/items")
async def call_items():
    async with httpx.AsyncClient() as client:
        return (await client.get("http://items-service:8000/items")).json()
