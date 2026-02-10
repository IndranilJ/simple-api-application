from typing import Optional, List, TYPE_CHECKING
from sqlmodel import SQLModel, Field, Relationship
from app.models.links import NoteTagLink

if TYPE_CHECKING:
    from app.models.note import Note
    from app.models.user import User

class TagBase(SQLModel):
    name: str = Field(index=True)  # Removed unique=True, tags are now per-user

class Tag(TagBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    
    # Relationships
    user: Optional["User"] = Relationship(back_populates="tags")
    notes: List["Note"] = Relationship(back_populates="tags", link_model=NoteTagLink)

class TagRead(TagBase):
    id: int
