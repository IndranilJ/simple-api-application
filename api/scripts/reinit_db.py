"""
Database reinitialization script.
Drops all existing tables and recreates them with the new schema including User model.
WARNING: This will delete all existing data!
"""
import asyncio
from sqlmodel import SQLModel
from sqlalchemy.ext.asyncio import create_async_engine
import os

# CRITICAL: Import all models to register them with SQLModel.metadata
from app.models.user import User
from app.models.note import Note
from app.models.tag import Tag
from app.models.links import NoteTagLink

# Get database URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://synapse:synapse123@localhost:5432/synapse_db")

# Create async engine for reinit
reinit_engine = create_async_engine(DATABASE_URL, echo=True)

async def reinit_database():
    """Drop all tables and recreate with new schema."""
    print("=" * 60)
    print("DATABASE REINITIALIZATION")
    print("=" * 60)
    print("\nWARNING: This will delete ALL existing data!")
    print("Press Ctrl+C within 5 seconds to cancel...\n")
    
    # Give user time to cancel
    await asyncio.sleep(5)
    
    print("Dropping all existing tables...")
    async with reinit_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)
    print("✓ All tables dropped")
    
    print("\nCreating new tables with authentication support...")
    async with reinit_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    print("✓ All tables created")
    
    print("\n" + "=" * 60)
    print("DATABASE REINITIALIZED SUCCESSFULLY!")
    print("=" * 60)
    print("\nNew schema includes:")
    print("  - user table (authentication)")
    print("  - note table (with user_id)")
    print("  - tag table (with user_id)")
    print("  - notetaglink table") 
    print("\nYou can now register users and create notes!")
    print("=" * 60)
    
    await reinit_engine.dispose()

if __name__ == "__main__":
    asyncio.run(reinit_database())
