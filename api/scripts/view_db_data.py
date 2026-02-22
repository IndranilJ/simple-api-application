import os
import asyncio
# from fastapi import FastAPI, Depends
# from sqlalchemy.orm import Session
# from sqlalchemy import create_engine, text
from datetime import datetime
from sqlmodel import SQLModel, Field, select
from sqlmodel.ext.asyncio.session import AsyncSession 
from sqlalchemy.ext.asyncio import create_async_engine 
from typing import AsyncGenerator, List, Optional

DATABASE_URL = os.getenv( "DATABASE_URL", "postgresql+asyncpg://synapse:synapse123@localhost:5432/synapse_db" )

# create async engine
engine = create_async_engine( DATABASE_URL, echo=True, future=True )
# print(engine)

#  User model
class User(SQLModel, table=True):
    
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True, max_length=255)
    name: str = Field(max_length=255)
    hashed_password: Optional[str] = Field(default=None, max_length=255)  # Null for OAuth-only users
    oauth_provider: Optional[str] = Field(default=None, max_length=50)    # 'google' or null
    oauth_id: Optional[str] = Field(default=None, max_length=255)         # Provider's user ID
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# Notes model
class Note(SQLModel, table=True):
    title: str
    content: str
    sentiment: Optional[str] = None
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)

# Tag model
class Tag(SQLModel, table=True):
    name: str = Field(index=True)  # Removed unique=True, tags are now per-user
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)


#  Tag-Note Link model
class NoteTagLink(SQLModel, table=True):
    note_id: Optional[int] = Field(default=None, foreign_key="note.id", primary_key=True)
    tag_id: Optional[int] = Field(default=None, foreign_key="tag.id", primary_key=True)


# async def init_db() -> None:
#     async with engine.begin() as conn:
#         await conn.run_sync( SQLModel.metadata.create_all )

async def get_users(session: AsyncSession) -> List[User]:
    # async with AsyncSession( engine ) as session:
        statement = select( User )
        result = await session.exec(statement)
        # users = result.scalars().all()
        users = result.all()
        return users
    
def print_user_details(users: List[User]) -> None:
    print("Total users:", len(users))
    print("User details:")
    for user in users:
        print(f"ID: {user.id}, Email: {user.email}, Name: {user.name}, OAuth Provider: {user.oauth_provider}, Created At: {user.created_at}, Updated At: {user.updated_at}")

async def get_notes(session: AsyncSession) -> List[Note]:
    # async with AsyncSession( engine ) as session:
        statement = select( Note )
        result = await session.exec(statement)
        notes = result.all()
        return notes

def print_note_details(notes: List[Note]) -> None:
    print("Total notes:", len(notes))
    print("Note details:")
    for note in notes:
        print(f"ID: {note.id}, Title: {note.title}, Content: {note.content}, Sentiment: {note.sentiment}, User ID: {note.user_id}")

async def get_tags(session: AsyncSession) -> List[Tag]:
    # async with AsyncSession( engine ) as session:
        statement = select( Tag )
        result = await session.exec(statement)
        tags = result.all()
        return tags

def print_tag_details(tags: List[Tag]) -> None:
    print("Total tags:", len(tags))
    print("Tag details:")
    for tag in tags:
        print(f"ID: {tag.id}, Name: {tag.name}, User ID: {tag.user_id}")

async def get_note_tag_links(session: AsyncSession) -> List[NoteTagLink]:
    # async with AsyncSession( engine ) as session:
        statement = select( NoteTagLink )
        result = await session.exec(statement)
        links = result.all()
        return links

def print_note_tag_links(links: List[NoteTagLink]) -> None:
    print("Total note-tag links:", len(links))
    print("Note-tag link details:")
    for link in links:
        print(f"Note ID: {link.note_id}, Tag ID: {link.tag_id}")

# def print_all_details_dontuse(users: List[User], notes: List[Note], tags: List[Tag], links: List[NoteTagLink]) -> None:
#     # Build lookup tables for users and tags
#     user_dict = {user.id: user for user in users}
#     tag_dict = {tag.id: tag for tag in tags}
#     # Map note_id to list of tag_ids
#     from collections import defaultdict
#     note_tags = defaultdict(list)
#     for link in links:
#         if link.note_id is not None and link.tag_id is not None:
#             note_tags[link.note_id].append(link.tag_id)

#     for note in notes:
#         print("-" * 80)
#         # Note details
#         print(f"Note ID: {note.id}")
#         print(f"Title: {note.title}")
#         print(f"Content: {note.content}")
#         print(f"Sentiment: {note.sentiment}")
#         print(f"User ID: {note.user_id}")
#         # User details
#         user = user_dict.get(note.user_id)
#         if user:
#             print(f"User Email: {user.email}")
#             print(f"User Name: {user.name}")
#             print(f"User OAuth Provider: {user.oauth_provider}")
#             print(f"User Created At: {user.created_at}")
#             print(f"User Updated At: {user.updated_at}")
#         else:
#             print("User: Not found")
#         # Tags for this note
#         tag_ids = note_tags.get(note.id, [])
#         if tag_ids:
#             print("Tags:")
#             for tag_id in tag_ids:
#                 tag = tag_dict.get(tag_id)
#                 if tag:
#                     print(f"  - {tag.name} (Tag ID: {tag.id})")
#                 else:
#                     print(f"  - Tag ID {tag_id} (not found)")
#         else:
#             print("Tags: None")
#         print("-" * 80)


def print_all_details(users : List[User], tags : List[Tag], notes : List[Note], noteTagLink : List[NoteTagLink]) -> None:
     dict_users = {}
     for user in users:
          dict_users[user.id] = user
     dict_tags = {}
     for tag in tags:
          dict_tags[tag.id] = tag
     dict_note_tags = {}
     for link in noteTagLink:
         if link.note_id is not None and link.tag_id is not None:
              if link.note_id not in dict_note_tags:
                   dict_note_tags[link.note_id] = []
              dict_note_tags[link.note_id].append(link.tag_id) 
     for note in notes:
          print('-'*80)
          print(f"Note ID : {note.id}")
          print(f"Note User ID: {note.user_id}")
          print(f"Note User Name: {dict_users[note.user_id].name}")
          print(f"Note User Email ID: {dict_users[note.user_id].email}")
          print(f"Note Title: {note.title}")
          print(f"Note Content: {note.content}")
          print(f"Note Sentiment: {note.sentiment}")
          print(f"Note Tags: {[dict_tags[tag_id].name for tag_id in dict_note_tags[note.id]]}")
          print('-'*80)


async def main():
    # await init_db()
    async with AsyncSession( engine ) as session:
        print("============================================================================================================")
        users = await get_users(session)
        # print_user_details(users)
        print("============================================================================================================")
        tags = await get_tags(session)
        # print_tag_details(tags)
        print("============================================================================================================")
        notes = await get_notes(session)
        # print_note_details(notes)
        print("============================================================================================================")
        links = await get_note_tag_links(session)
        # print_note_tag_links(links)
        print("============================================================================================================")
        print_all_details(users, tags, notes, links)
        print("============================================================================================================")


if __name__ == "__main__":
    asyncio.run(main())