from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import notes, tags, auth
from app.db import init_db

# Create the main application
app = FastAPI(title="Synapse", version="1.0.0")

# Allow the frontend to talk to us
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173", "http://localhost"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def on_startup():
    await init_db()

# Include API routers
app.include_router(auth.router)
app.include_router(notes.router)
app.include_router(tags.router)

@app.get("/")
def root():
    return {"message": "Welcome to Synapse: Your Digital Second Brain"}