from typing import Optional, List, TYPE_CHECKING
from sqlmodel import SQLModel, Field, Relationship
from app.models.links import NoteTagLink

if TYPE_CHECKING:
    from app.models.tag import Tag
    from app.models.user import User

from app.models.tag import Tag, TagRead

class NoteBase(SQLModel):
    title: str
    content: str
    sentiment: Optional[str] = None

class Note(NoteBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    
    # Relationships
    user: Optional["User"] = Relationship(back_populates="notes")
    tags: List["Tag"] = Relationship(back_populates="notes", link_model=NoteTagLink)

class NoteCreate(NoteBase):
    tags: List[str] = []

class NoteRead(NoteBase):
    id: int
    tags: List[TagRead] = []
