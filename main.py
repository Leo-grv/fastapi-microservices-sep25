from fastapi import FastAPI
import httpx
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

@app.on_event("startup")
async def start_metrics():
    Instrumentator().instrument(app).expose(app, endpoint="/metrics")

@app.get("/")
def root():
    return {"gateway": "ok"}

@app.get("/auth")
async def proxy_auth():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://auth-service:8000/auth")
        return r.json()

@app.get("/items")
async def proxy_items():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://items-service:8000/items")
        return r.json()

@app.get("/users")
async def proxy_users():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://users-service:8000/users")
        return r.json()
