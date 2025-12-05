from fastapi import FastAPI
import httpx

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Gateway OK"}

@app.get("/auth")
async def call_auth():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://auth:8000/auth")
        return r.json()

@app.get("/users")
async def call_users():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://users:8000/users")
        return r.json()

@app.get("/items")
async def call_items():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://items:8000/items")
        return r.json()
