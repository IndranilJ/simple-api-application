"""
JWT token creation and verification utilities.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from pydantic import BaseModel
from app.config import settings

class TokenData(BaseModel):
    """Token payload data."""
    user_id: int
    email: str

class Token(BaseModel):
    """Token response model."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict) -> str:
    """Create a JWT refresh token."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_token(token: str, token_type: str = "access") -> Optional[TokenData]:
    """
    Verify and decode a JWT token.
    Returns TokenData if valid, None otherwise.
    """
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        # Check token type
        if payload.get("type") != token_type:
            return None
        
        # JWT spec requires 'sub' to be a string, so we convert it back to int
        user_id_str: str = payload.get("sub")
        email: str = payload.get("email")
        
        if user_id_str is None or email is None:
            return None
        
        # Convert user_id from string back to int
        try:
            user_id = int(user_id_str)
        except (ValueError, TypeError):
            return None
        
        return TokenData(user_id=user_id, email=email)
    
    except JWTError:
        return None

def create_tokens(user_id: int, email: str) -> Token:
    """Create both access and refresh tokens for a user."""
    # JWT spec requires 'sub' field to be a string
    token_data = {"sub": str(user_id), "email": email}
    
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    return Token(
        access_token=access_token,
        refresh_token=refresh_token
    )
