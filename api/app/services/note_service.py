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

    async def get_or_create_tags(self, tag_names: List[str]) -> List[Tag]:
        """
        Optimized bulk tag retrieval and creation.
        Solves the N+1 problem by using a single batch query.
        """
        if not tag_names:
            return []
            
        # 1. Fetch all existing tags in one query
        statement = select(Tag).where(
            Tag.name.in_(tag_names), 
            Tag.user_id == self.user_id
        )
        result = await self.session.exec(statement)
        existing_tags = {tag.name: tag for tag in result.all()}
        
        # 2. Identify and create missing tags
        final_tags = []
        for name in tag_names:
            if name in existing_tags:
                final_tags.append(existing_tags[name])
            else:
                new_tag = Tag(name=name, user_id=self.user_id)
                self.session.add(new_tag)
                final_tags.append(new_tag)
        
        # 3. Flush to ensure all new tags have IDs
        if any(name not in existing_tags for name in tag_names):
            await self.session.flush()
            
        return final_tags

    async def create_note(self, note_data: NoteCreate) -> Note:
        # Create Note excluding tags
        note_dict = note_data.dict(exclude={"tags"})
        note = Note(**note_dict, user_id=self.user_id)
        
        # Handle tags efficiently in bulk
        if note_data.tags:
            tags = await self.get_or_create_tags(note_data.tags)
            note.tags = tags
        
        self.session.add(note)
        await self.session.commit()
        await self.session.refresh(note)
        
        # Re-fetch with tags to ensure response consistency
        return await self.get_note_by_id(note.id)

    async def get_note_by_id(self, note_id: int) -> Optional[Note]:
        """Get a single note by ID with tags eagerly loaded."""
        statement = select(Note).where(
            Note.id == note_id, 
            Note.user_id == self.user_id
        ).options(selectinload(Note.tags))
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
        note = await self.get_note_by_id(note_id)
        
        if note:
            note.title = note_data.title
            note.content = note_data.content
            
            # Efficiently sync tags
            if note_data.tags:
                tags = await self.get_or_create_tags(note_data.tags)
                note.tags = tags
            else:
                note.tags = []
            
            self.session.add(note)
            await self.session.commit()
            
            # Refresh to ensure latest state
            return await self.get_note_by_id(note_id)
            
        return None

# Why a Service? 
# 1. Reusability: You can use this logic in API, background tasks, or scripts.
# 2. Testing: It's easier to test "create_note" without spinning up a whole web server.
# 3. Data Isolation: All operations automatically filter by user_id for security.
