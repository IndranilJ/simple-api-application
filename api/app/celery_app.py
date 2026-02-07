from celery import Celery

# 1. Create the Celery App
# "synapse" is the name of our worker.
# broker="..." tells Celery where the Redis Ticket Wheel is.
# backend="..." tells Celery where to store the results (also Redis).
celery_app = Celery(
    "synapse",
    broker="redis://localhost:6379/0",
    backend="redis://localhost:6379/0"
)

# 2. Configure Settings
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
)
