import httpx
import asyncio

async def test_api():
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8001") as client:
        # 1. Create a Note
        print("Creating a note...")
        response = await client.post("/notes", json={"title": "Test Note", "content": "This is a test"})
        print("Create Response:", response.status_code, response.json())

        # 2. Read Notes
        print("Reading notes...")
        response = await client.get("/notes")
        print("Read Response:", response.status_code, response.json())

if __name__ == "__main__":
    asyncio.run(test_api())
