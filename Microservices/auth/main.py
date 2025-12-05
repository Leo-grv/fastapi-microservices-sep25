from fastapi import FastAPI

app = FastAPI()

@app.get("/auth")
def auth_root():
    return {"message": "Auth service OK"}
