from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Hello API", version="1.0.0")

class Echo(BaseModel):
    message: str

@app.get("/")
def desc():
    return {"Allowed methods": "/health [GET], /hello [GET], /echo [POST]"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/hello")
def hello(name: str = "world"):
    return {"greeting": f"Hello, {name}!"}

@app.post("/echo")
def echo(payload: Echo):
    return {"you_said": payload.message}