from fastapi import FastAPI

app = FastAPI()

@app.get("/users")
def list_users():
    return {"users": ["alice", "bob", "charlie"]}
