from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncEngine

# 1. Create the Database URL
# We use SQLite for simplicity. "sqlite+aiosqlite:///" tells it to use the async driver.
DATABASE_URL = "sqlite+aiosqlite:///./synapse.db"

# 2. Create the Engine
# The engine is the factory that churns out connections to the database.
engine = create_async_engine(DATABASE_URL, echo=True, future=True)

# 3. Create a "Session Maker"
# This helper creates new database sessions for each request.
async_session = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

# 4. Dependency to get the DB session
# We will use this in our API endpoints: "def get_notes(db: AsyncSession = Depends(get_session))"
async def get_session() -> AsyncSession:
    async with async_session() as session:
        yield session

# 5. Helper to create tables
async def init_db():
    async with engine.begin() as conn:
        # This looks at all classes inheriting from SQLModel and creates tables for them
        await conn.run_sync(SQLModel.metadata.create_all)
