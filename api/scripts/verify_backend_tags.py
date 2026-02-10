import asyncio
from app.db import get_session, init_db
from app.services.note_service import NoteService
from app.models.note import NoteCreate

async def verify():
    await init_db()
    async for session in get_session():
        service = NoteService(session)
        
        # Create Note with Tags
        print("Creating note with tags...")
        note_data = NoteCreate(title="Tagged Note", content="Has tags", tags=["work", "important"])
        created_note = await service.create_note(note_data)
        print(f"Created Note ID: {created_note.id}")
        print(f"Tags: {[t.name for t in created_note.tags]}")
        
        assert len(created_note.tags) == 2
        assert "work" in [t.name for t in created_note.tags]
        
        # Update Note tags
        print("Updating note tags...")
        update_data = NoteCreate(title="Tagged Note Updated", content="Has tags", tags=["personal", "work"])
        updated_note = await service.update_note(created_note.id, update_data)
        print(f"Updated Tags: {[t.name for t in updated_note.tags]}")
        
        assert len(updated_note.tags) == 2
        assert "personal" in [t.name for t in updated_note.tags]
        
        # Cleanup
        await service.delete_note(created_note.id)
        print("Verification Successful!")
        break

if __name__ == "__main__":
    asyncio.run(verify())
