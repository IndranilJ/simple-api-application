from celery import Celery
from app.config import settings

# Create the Celery App using settings
celery_app = Celery(
    "synapse",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.tasks"]
)

# 2. Configure Settings
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
)
