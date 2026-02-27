from app.celery_app import celery_app
from sqlmodel import Session, create_engine, select
from app.models.note import Note
from app.config import settings
import time
import logging

# Configure Logging
logger = logging.getLogger(__name__)

# Create Synchronous Engine for Celery tasks using setting utilities
engine = create_engine(settings.SYNC_DATABASE_URL_READY)

@celery_app.task(bind=True, max_retries=3)
def analyze_note_task(self, note_id: int):
    """
    Simulates a heavy AI analysis task and saves the result.
    Standardizes on Positive, Negative, or Neutral labels.
    """
    logger.info(f"Starting analysis for note {note_id}...")
    time.sleep(3)  # Slightly faster simulation
    
    # Keyword Scoring Engine
    pos_keywords = {"good", "great", "awesome", "success", "happy", "fixed", "resolved", "working", "amazing", "love"}
    neg_keywords = {"bad", "issue", "bug", "error", "failing", "broken", "worst", "terrible", "problem", "broken"}
    
    sentiment = "Neutral"
    
    try:
        # Write to DB
        with Session(engine) as session:
            note = session.get(Note, note_id)
            if note:
                # Score the content
                content_lower = note.content.lower()
                score = 0
                
                for word in pos_keywords:
                    if word in content_lower:
                        score += 1
                for word in neg_keywords:
                    if word in content_lower:
                        score -= 1
                
                if score > 0:
                    sentiment = "Positive"
                elif score < 0:
                    sentiment = "Negative"
                
                note.sentiment = sentiment
                session.add(note)
                session.commit()
                logger.info(f"Updated note {note_id} with sentiment: {sentiment} (Score: {score})")
            else:
                logger.warning(f"Note {note_id} not found!")
    except Exception as exc:
        logger.error(f"Error analyzing note {note_id}: {exc}")
        # Auto-retry with exponential backoff if DB connection fails
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)
            
    return sentiment
