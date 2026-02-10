from sqlmodel import select, col
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.orm import selectinload
from typing import List, Optional
from app.models.note import Note, NoteCreate
from app.models.tag import Tag

class NoteService:
    def __init__(self, session: AsyncSession, user_id: int):
        self.session = session
        self.user_id = user_id

    async def get_all_notes(self, query: str = None, tag: str = None) -> List[Note]:
        statement = select(Note).where(Note.user_id == self.user_id).options(selectinload(Note.tags))
        
        # Filter by tag if specified
        if tag:
            statement = statement.join(Note.tags).where(Tag.name == tag)
        
        # Filter by text search if specified
        if query:
            statement = statement.where(
                col(Note.title).contains(query) | col(Note.content).contains(query)
            )
        
        result = await self.session.exec(statement)
        return result.all()

    async def get_or_create_tag(self, tag_name: str) -> Tag:
        # Tags are now user-specific
        statement = select(Tag).where(Tag.name == tag_name, Tag.user_id == self.user_id)
        result = await self.session.exec(statement)
        tag = result.first()
        if not tag:
            tag = Tag(name=tag_name, user_id=self.user_id)
            self.session.add(tag)
            # Use flush instead of commit to keep the object in session
            await self.session.flush()
            # Refresh is safe here because we just flushed
            await self.session.refresh(tag)
        return tag

    async def create_note(self, note_data: NoteCreate) -> Note:
        # Create Note excluding tags (which are list of strings in input)
        note_dict = note_data.dict(exclude={"tags"})
        note = Note(**note_dict, user_id=self.user_id)
        
        # Handle tags
        if note_data.tags:
            for tag_name in note_data.tags:
                tag = await self.get_or_create_tag(tag_name)
                note.tags.append(tag)
        
        self.session.add(note)
        await self.session.commit()
        await self.session.refresh(note)
        # Re-fetch with tags to ensure they are loaded for response
        statement = select(Note).where(Note.id == note.id).options(selectinload(Note.tags))
        result = await self.session.exec(statement)
        return result.one()

    async def get_note_by_id(self, note_id: int) -> Optional[Note]:
        """Get a single note by ID, ensuring it belongs to the user."""
        statement = select(Note).where(Note.id == note_id, Note.user_id == self.user_id).options(selectinload(Note.tags))
        result = await self.session.exec(statement)
        return result.first()

    async def delete_note(self, note_id: int) -> bool:
        note = await self.get_note_by_id(note_id)
        if note:
            await self.session.delete(note)
            await self.session.commit()
            return True
        return False


    async def update_note(self, note_id: int, note_data: NoteCreate) -> Optional[Note]:
        # Fetch note with tags eagerly loaded
        statement = select(Note).where(Note.id == note_id, Note.user_id == self.user_id).options(selectinload(Note.tags))
        result = await self.session.exec(statement)
        note = result.first()
        
        if note:
            note.title = note_data.title
            note.content = note_data.content
            
            # Clear existing tags from relationship (this is sync, but safe before commit)
            note.tags.clear()
            
            # Add new tags using get_or_create
            if note_data.tags:
                for tag_name in note_data.tags:
                    tag = await self.get_or_create_tag(tag_name)
                    note.tags.append(tag)
            
            # Commit once at the end
            self.session.add(note)
            await self.session.commit()
            
            # Re-fetch to ensure tags are loaded
            statement_refetch = select(Note).where(Note.id == note_id).options(selectinload(Note.tags))
            result_refetch = await self.session.exec(statement_refetch)
            return result_refetch.one()
            
        return None

# Why a Service? 
# 1. Reusability: You can use this logic in API, background tasks, or scripts.
# 2. Testing: It's easier to test "create_note" without spinning up a whole web server.
# 3. Data Isolation: All operations automatically filter by user_id for security.
