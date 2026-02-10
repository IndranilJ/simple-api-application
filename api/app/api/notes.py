from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlmodel.ext.asyncio.session import AsyncSession
from app.models.note import Note, NoteCreate, NoteRead
from app.models.user import User
from app.db import get_session
from app.services.note_service import NoteService
from app.auth import get_current_user

router = APIRouter()

# Helper to get the service with user context
async def get_note_service(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user)
) -> NoteService:
    return NoteService(session, current_user.id)

@router.post("/notes", response_model=NoteRead)
async def create_note(
    note: NoteCreate, 
    service: NoteService = Depends(get_note_service)
):
    """Create a new note for the authenticated user."""
    return await service.create_note(note)

@router.get("/notes", response_model=List[NoteRead])
async def read_notes(
    q: Optional[str] = None,
    tag: Optional[str] = None,
    service: NoteService = Depends(get_note_service)
):
    """Get all notes for the authenticated user, with optional search and tag filtering."""
    return await service.get_all_notes(query=q, tag=tag)

@router.get("/notes/{note_id}", response_model=NoteRead)
async def get_note(
    note_id: int,
    service: NoteService = Depends(get_note_service)
):
    """Get a single note by ID."""
    note = await service.get_note_by_id(note_id)
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found"
        )
    return note

from app.tasks import analyze_note_task

@router.post("/notes/{note_id}/analyze")
async def analyze_note(
    note_id: int,
    service: NoteService = Depends(get_note_service)
):
    """Trigger sentiment analysis for a note (must belong to current user)."""
    # Verify note belongs to user
    note = await service.get_note_by_id(note_id)
    if not note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found"
        )
    
    # Trigger the background task
    task = analyze_note_task.delay(note_id)
    return {"message": "Analysis started", "task_id": task.id}

@router.put("/notes/{note_id}", response_model=NoteRead)
async def update_note(
    note_id: int,
    note: NoteCreate,
    service: NoteService = Depends(get_note_service)
):
    """Update a note."""
    updated_note = await service.update_note(note_id, note)
    if not updated_note:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found"
        )
    return updated_note

@router.delete("/notes/{note_id}")
async def delete_note(
    note_id: int,
    service: NoteService = Depends(get_note_service)
):
    """Delete a note."""
    success = await service.delete_note(note_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found"
        )
    return {"message": "Note deleted successfully"}
