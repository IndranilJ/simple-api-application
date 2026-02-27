"""
Redis client for token blacklisting.
Used to invalidate JWT tokens on logout.
"""
from app.config import settings
import redis

# Synchronous Redis client using centralized settings
redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


def blacklist_token(token: str, expires_in_seconds: int) -> None:
    """
    Add a token to the blacklist.
    It will automatically be removed after expires_in_seconds (matching the token's own TTL).
    """
    redis_client.setex(f"blacklist:{token}", expires_in_seconds, "true")


def is_token_blacklisted(token: str) -> bool:
    """
    Check if a token has been blacklisted (i.e. user has logged out).
    Returns True if the token is invalid/blacklisted.
    """
    return redis_client.exists(f"blacklist:{token}") == 1
