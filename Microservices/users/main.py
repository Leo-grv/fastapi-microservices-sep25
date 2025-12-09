from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from database import SessionLocal, engine
import models

app = FastAPI()

@app.on_event("startup")
def on_startup():
    models.Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class UserCreate(BaseModel):
    username: str
    password: str

@app.post("/users")
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    new_user = models.User(username=user.username, password=user.password)
    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return {"message": "User created", "id": new_user.id}
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Username already exists")

@app.get("/users")
def list_users(db: Session = Depends(get_db)):
    users = db.query(models.User).all()
    return [{"id": u.id, "username": u.username} for u in users]

@app.post("/users/check")
def check_user(data: dict, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.username == data["username"]).first()
    if user:
        return {"exists": True, "id": user.id}
    return {"exists": False}
