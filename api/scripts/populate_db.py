"""
Populate the database with sample notes and tags for testing.
"""

import requests
import time

API_BASE_URL = "http://localhost:8004"

# Sample notes with realistic data
sample_notes = [
    {
        "title": "Grocery List",
        "content": "Buy milk, eggs, bread, and fresh vegetables. Don't forget to check for discounts on fruits.",
        "tags": ["shopping", "personal"]
    },
    {
        "title": "Project Brainstorm",
        "content": "Explore ideas for automating CI/CD pipelines with Jenkins and Docker. Draft a roadmap for integrating SonarQube and Nexus.",
        "tags": ["work", "devops", "ideas"]
    },
    {
        "title": "Weekend Plans",
        "content": "Catch up on reading, go for a hike near Mulshi Lake, and try out a new recipe.",
        "tags": ["personal", "leisure"]
    },
    {
        "title": "Meeting Notes",
        "content": "Discussed Q1 goals, budget allocation, and monitoring setup with Prometheus + Grafana. Action items: finalize deployment strategy by Friday.",
        "tags": ["work", "meeting"]
    },
    {
        "title": "Book Ideas",
        "content": "Draft outline for a technical guide on container orchestration. Include chapters on Docker Compose, Kubernetes basics, and CI/CD integration.",
        "tags": ["writing", "tech", "ideas"]
    }
]

def populate_database():
    """Create sample notes in the database."""
    print("Starting database population...\n")
    
    created_count = 0
    for i, note_data in enumerate(sample_notes, 1):
        print(f"Creating note {i}/{len(sample_notes)}: {note_data['title']}")
        
        try:
            response = requests.post(
                f"{API_BASE_URL}/notes",
                json=note_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                created_note = response.json()
                print(f"   [OK] Created with ID: {created_note['id']}")
                print(f"   Tags: {', '.join(note_data['tags'])}")
                created_count += 1
            else:
                print(f"   [FAIL] Failed: {response.status_code} - {response.text}")
        
        except requests.exceptions.RequestException as e:
            print(f"   [ERROR] {e}")
        
        time.sleep(0.2)  # Small delay between requests
    
    print(f"\nDatabase population complete!")
    print(f"   Created {created_count}/{len(sample_notes)} notes")
    
    # Verify tags were created
    try:
        tags_response = requests.get(f"{API_BASE_URL}/tags")
        if tags_response.status_code == 200:
            tags = tags_response.json()
            print(f"   Total tags in database: {len(tags)}")
            print(f"   Tags: {', '.join([tag['name'] for tag in tags])}")
    except:
        pass

if __name__ == "__main__":
    populate_database()
