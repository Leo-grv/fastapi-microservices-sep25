from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

Instrumentator().instrument(app).expose(app, endpoint="/items/metrics")

@app.get("/items")
def get_items():
    return {"items": ["item1", "item2", "item3"]}
