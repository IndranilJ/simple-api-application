import os
from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.ext.asyncio import create_async_engine
from typing import AsyncGenerator

# Database configuration from environment variables
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://synapse:synapse123@localhost:5432/synapse_db"
)

# Create async engine for PostgreSQL
engine = create_async_engine(
    DATABASE_URL,
    echo=True,  # Set to False in production
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

