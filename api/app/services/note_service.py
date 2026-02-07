from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession
from typing import List
from app.models.note import Note

class NoteService:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_all_notes(self) -> List[Note]:
        result = await self.session.exec(select(Note))
        return result.all()

    async def create_note(self, note: Note) -> Note:
        self.session.add(note)
        await self.session.commit()
        await self.session.refresh(note)
        return note

# Why a Service? 
# 1. Reusability: You can use this logic in API, background tasks, or scripts.
# 2. Testing: It's easier to test "create_note" without spinning up a whole web server.
