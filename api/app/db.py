import os
from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.ext.asyncio import create_async_engine
from typing import AsyncGenerator

from app.config import settings

# Create async engine for PostgreSQL using settings
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True
)

async def init_db():
    """Initialize database tables."""
    async with engine.begin() as conn:
        # This looks at all classes inheriting from SQLModel and creates tables for them
        await conn.run_sync(SQLModel.metadata.create_all)

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get database session."""
    async with AsyncSession(engine) as session:
        yield session

