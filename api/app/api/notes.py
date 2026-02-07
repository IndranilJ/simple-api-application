from fastapi import APIRouter, Depends
from typing import List
from sqlmodel.ext.asyncio.session import AsyncSession
from app.models.note import Note
from app.db import get_session
from app.services.note_service import NoteService

router = APIRouter()

# Helper to get the service
async def get_note_service(session: AsyncSession = Depends(get_session)) -> NoteService:
    return NoteService(session)

@router.post("/notes", response_model=Note)
async def create_note(
    note: Note, 
    service: NoteService = Depends(get_note_service)
):
    return await service.create_note(note)

@router.get("/notes", response_model=List[Note])
async def read_notes(
    service: NoteService = Depends(get_note_service)
):
    return await service.get_all_notes()

from app.tasks import analyze_note_task

@router.post("/notes/{note_id}/analyze")
async def analyze_note(note_id: int):
    # Trigger the background task
    task = analyze_note_task.delay(note_id)
    return {"message": "Analysis started", "task_id": task.id}
