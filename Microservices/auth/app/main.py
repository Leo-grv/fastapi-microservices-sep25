from fastapi import FastAPI
from sqlmodel import SQLModel
from app.api.routes import login
from app.core.db import engine
from app.api.routes import login, verify  


app = FastAPI(title="Auth Service")

# Add API and service prefix
app.include_router(login.router, prefix="/auth")
app.include_router(verify.router)  

# --- DATABASE INIT ---
@app.on_event("startup")
def on_startup():
    print("Initializing database...")
    SQLModel.metadata.create_all(engine)
