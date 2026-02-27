from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.api import notes, tags, auth
from app.db import init_db

import os

# Create the main application
# root_path allows the API to function correctly behind a proxy/prefix (/api)
app = FastAPI(
    title="Synapse", 
    version="1.0.0",
    root_path=os.getenv("ROOT_PATH", "")
)

# Allow the frontend to talk to us
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALL_ORIGINS,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",  # any local port (Flutter dev)
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