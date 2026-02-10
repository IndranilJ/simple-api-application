from app.celery_app import celery_app
from sqlmodel import Session, create_engine, select
from app.models.note import Note
import time
import os

# Get database URL from environment (same as main app)
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://synapse:synapse123@localhost:5432/synapse_db"
)
# Use sync driver for Celery (psycopg2 instead of asyncpg)
SYNC_DATABASE_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

# Sync engine for Celery worker
engine = create_engine(SYNC_DATABASE_URL)

@celery_app.task
def analyze_note_task(note_id: int):
    """
    Simulates a heavy AI analysis task and saves the result.
    """
    print(f"Starting analysis for note {note_id}...")
    time.sleep(5)  # Simulate processing
    
    # Simple logic: bigger notes are "Insightful", short ones are "Brief"
    sentiment = "Insightful"
    
    # Write to DB
    with Session(engine) as session:
        note = session.get(Note, note_id)
        if note:
            # Analyze content length for variety
            if len(note.content) < 20:
                sentiment = "Brief"
            
            note.sentiment = sentiment
            session.add(note)
            session.commit()
            print(f"Updated note {note_id} with sentiment: {sentiment}")
        else:
            print(f"Note {note_id} not found!")
            
    return sentiment
