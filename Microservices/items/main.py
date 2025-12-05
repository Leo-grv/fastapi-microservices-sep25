from fastapi import FastAPI

app = FastAPI()

@app.get("/items")
def get_items():
    return {"items": ["item1", "item2", "item3"]}
