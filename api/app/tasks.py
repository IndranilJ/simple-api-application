from app.celery_app import celery_app
import time

@celery_app.task
def analyze_note_task(note_id: int):
    """
    Simulates a heavy AI analysis task.
    """
    print(f"Starting analysis for note {note_id}...")
    time.sleep(10)  # Simulate 10 seconds of processing
    result = f"Analysis complete for note {note_id}: Sentiment is Positive."
    print(result)
    return result
