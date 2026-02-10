from fastapi import APIRouter, Depends
from typing import List
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlmodel import select, func
from app.models.tag import Tag
from app.models.user import User
from app.models.links import NoteTagLink
from app.db import get_session
from app.auth import get_current_user

router = APIRouter()

@router.get("/tags", response_model=List[dict])
async def get_all_tags(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """Get all tags belonging to the user with their usage counts, sorted by popularity."""
    # Get all tags for the current user with their note count   
    statement = select(Tag.id, Tag.name, func.count(NoteTagLink.note_id).label('count')) \
        .where(Tag.user_id == current_user.id) \
        .outerjoin(NoteTagLink, Tag.id == NoteTagLink.tag_id) \
        .group_by(Tag.id, Tag.name) \
        .order_by(func.count(NoteTagLink.note_id).desc())
    
    result = await session.exec(statement)
    tags = [{"id": row[0], "name": row[1], "count": row[2]} for row in result.all()]
    return tags
