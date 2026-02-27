# 🛠️ Synapse: Backend Developer Deep-Dive

Welcome to the engineering engine of Synapse. This guide provides a senior-level perspective on the backend architecture, designed to help you write code that is secure, fast, and maintainable.

---

## 🏗️ Core Architectural Pillars

We use a **Layered Architecture** to separate concerns. This ensures that a change in the database doesn't break the API routes, and vice-versa.

### 1. Configuration (`app/config.py`)
**Philosophy**: "If it's an environment variable, it belongs in Config."
- We use `pydantic-settings` to load and validate configurations at startup.
- **Why?**: This prevents the "missing secret" crash in production.
- **Junior Tip**: Never use `os.getenv()` in your logic. Always use `from app.config import settings`.

### 2. The Database Layer (`app/db.py` & `app/models/`)
We use **SQLModel** (a hybrid of Pydantic and SQLAlchemy) for an async, type-safe experience.
- **`AsyncSession`**: All API database operations are asynchronous.
- **Life Cycle**: Use the `get_session` dependency in your routes to ensure sessions are closed automatically.
- **Models vs Schemas**: 
    - `NoteBase`: Common fields.
    - `Note`: The actual table (`table=True`).
    - `NoteRead`: Use this for API responses to avoid leaking internal IDs or sensitive data.

### 3. The Service Layer (`app/services/`) — "The Brain"
**Crucial Rule**: **No business logic in routes.** Routes should only handle HTTP status codes and parameter validation.
- All database queries and core logic live in `NoteService`.
- **N+1 Optimization**: When fetching objects with relationships (like Notes with Tags), always use `selectinload`.
  ```python
  # Senior Pattern: Batch loading tags to avoid N+1 queries
  select(Note).options(selectinload(Note.tags))
  ```

### 4. Background Processing (`app/tasks.py`)
Heavy computations (AI Sentiment Analysis) are offloaded to **Celery**.
- **The Flow**: API sends ID to Redis ➡️ Celery Worker picks it up ➡️ Worker updates DB.
- **Resiliency**: We use **Exponential Backoff** for retries. If the DB is locked, the task waits and tries again automatically.
- **Logging**: Use `logger.info()` instead of `print()`. This is essential for monitoring in production.

---

## 🔒 Security & Auth (`app/auth/`)

- **JWT Utilities**: We use `jose` for secure token signing. We store the `user_id` and `email` in the payload.
- **Password Safety**: We use `bcrypt` for hashing. We *never* store plain-text passwords.
- **Dependencies**: `get_current_user` is the gatekeeper. Add it to any route to make it private.

---

## 🚀 "How Do I..." Tutorial

### **"How do I add a new API endpoint to track 'Archived' status?"**

1.  **Model Update (`models/note.py`)**: 
    Add `is_archived: bool = False` to `NoteBase`.
2.  **Service Logic (`services/note_service.py`)**:
    Add `async def archive_note(self, note_id: int) -> Optional[Note]:`.
    Pattern: `Fetch note -> check ownership -> set is_archived=True -> Commit -> Refresh`.
3.  **Route Definition (`api/notes.py`)**:
    Add `@router.patch("/{id}/archive")` and call your service method.
4.  **Verification**: 
    Run the API docs at `/docs` (Swagger) and test the new endpoint.

---

## 💡 Senior Best Practices

1.  **Centralize Exceptions**: Use the global exception handler in `main.py` instead of scattering `try/except` blocks in every route.
2.  **Bulk Operations**: If you have a loop that calls a DB query, refactor it into a single `IN` query. (See `NoteService.get_or_create_tags`).
3.  **UTC Always**: Always use `datetime.now(timezone.utc)` for timestamps to avoid timezone bugs.
4.  **Type Hints**: Use them everywhere. It makes the code self-documenting for other devs.

---

*This guide is part of the Synapse Technical Blueprint. For frontend details, please refer to the `FRONTEND_DEV_GUIDE.md`.*
