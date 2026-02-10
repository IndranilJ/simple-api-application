from celery import Celery
import os

# Get Redis URL from environment or use default
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# Create the Celery App
celery_app = Celery(
    "synapse",
    broker=REDIS_URL,
    backend=REDIS_URL,
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
