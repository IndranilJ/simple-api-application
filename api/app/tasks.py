from app.celery_app import celery_app
from sqlmodel import Session, create_engine, select
from app.models.note import Note
import time
import os

from urllib.parse import urlparse, parse_qs

# Priority: SYNC_DATABASE_URL (Cloud Run worker) → DATABASE_URL → localhost fallback
_raw = os.getenv(
    "SYNC_DATABASE_URL",
    os.getenv("DATABASE_URL", "postgresql://synapse:synapse123@localhost:5432/synapse_db")
).replace("postgresql+asyncpg://", "postgresql://")

# psycopg2 ignores ?host= query param in the URL.
# For Cloud SQL Unix sockets we must extract the socket path and pass it via connect_args.
_parsed = urlparse(_raw)
_socket_path = parse_qs(_parsed.query).get("host", [None])[0]

if _socket_path:
    # Cloud SQL socket: strip query string from URL, pass host via connect_args
    _db_url = f"postgresql+psycopg2://{_parsed.username}:{_parsed.password}@/{_parsed.path.lstrip('/')}"
    engine = create_engine(_db_url, connect_args={"host": _socket_path})
else:
    # Local TCP connection
    engine = create_engine(_raw)

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
