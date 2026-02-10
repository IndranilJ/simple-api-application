"""
User model for authentication and multi-user support.
"""
from datetime import datetime
from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship

class User(SQLModel, table=True):
    """User model supporting both email/password and OAuth authentication."""
    __tablename__ = "user"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True, max_length=255)
    name: str = Field(max_length=255)
    hashed_password: Optional[str] = Field(default=None, max_length=255)  # Null for OAuth-only users
    oauth_provider: Optional[str] = Field(default=None, max_length=50)    # 'google' or null
    oauth_id: Optional[str] = Field(default=None, max_length=255)         # Provider's user ID
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    notes: List["Note"] = Relationship(back_populates="user")
    tags: List["Tag"] = Relationship(back_populates="user")
