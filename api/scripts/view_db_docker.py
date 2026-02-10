"""
 Database Viewer Script
View all data in the Synapse database using Docker.

Usage:
    python scripts/view_db_docker.py
"""

import subprocess
import json


def run_query(query):
    """Run SQL query in Docker PostgreSQL container."""
    cmd = [
        'docker', 'exec', 'synapse_postgres',
        'psql', '-U', 'synapse', '-d', 'synapse_db',
        '-t', '-A', '-F', '|',
        '-c', query
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip()


def main():
    print("\n" + "="*80)
    print("SYNAPSE DATABASE CONTENTS")
    print("="*80 + "\n")
    
    # ========== USERS ==========
    print("USERS")
    print("-" * 80)
    query = "SELECT id, email, name, created_at FROM \"user\" ORDER BY id;"
    result = run_query(query)
    
    if not result:
        print("  No users found.\n")
    else:
        for line in result.split('\n'):
            if line:
                parts = line.split('|')
                print(f"  [{parts[0]}] {parts[2]}")
                print(f"      Email: {parts[1]}")
                print(f"      Created: {parts[3]}")
                print()
    
    user_count = run_query("SELECT COUNT(*) FROM \"user\";")
    print(f"Total Users: {user_count}\n")
    
    # ========== NOTES ==========
    print("NOTES")
    print("-" * 80)
    query = """
        SELECT n.id, n.title, u.email, n.content, n.sentiment, n.created_at 
        FROM note n 
        JOIN \"user\" u ON n.user_id = u.id 
        ORDER BY n.id;
    """
    result = run_query(query)
    
    if not result:
        print("  No notes found.\n")
    else:
        for line in result.split('\n'):
            if line:
                parts = line.split('|')
                note_id = parts[0]
                title = parts[1]
                owner = parts[2]
                content = parts[3]
                sentiment = parts[4] if len(parts) > 4 and parts[4] else None
                created = parts[5] if len(parts) > 5 else ''
                
                print(f"  [{note_id}] {title}")
                print(f"      Owner: {owner}")
                print(f"      Content: {content[:100]}{'...' if len(content) > 100 else ''}")
                
                # Get tags for this note
                tag_query = f"""
                    SELECT t.name 
                    FROM tag t 
                    JOIN notetaglink ntl ON t.id = ntl.tag_id 
                    WHERE ntl.note_id = {note_id};
                """
                tags_result = run_query(tag_query)
                if tags_result:
                    tags = tags_result.replace('\n', ', ')
                    print(f"      Tags: {tags}")
                
                if sentiment:
                    print(f"      Sentiment: {sentiment}")
                print(f"      Created: {created}")
                print()
    
    note_count = run_query("SELECT COUNT(*) FROM note;")
    print(f"Total Notes: {note_count}\n")
    
    # ========== TAGS ==========
    print("TAGS")
    print("-" * 80)
    query = """
        SELECT t.id, t.name, u.email,
        (SELECT COUNT(*) FROM notetaglink WHERE tag_id = t.id) as note_count
        FROM tag t
        JOIN \"user\" u ON t.user_id = u.id
        ORDER BY note_count DESC, t.name;
    """
    result = run_query(query)
    
    if not result:
        print("  No tags found.\n")
    else:
        for line in result.split('\n'):
            if line:
                parts = line.split('|')
                print(f"  [{parts[0]}] {parts[1]}")
                print(f"      Owner: {parts[2]}")
                print(f"      Used in {parts[3]} note(s)")
                print()
    
    tag_count = run_query("SELECT COUNT(*) FROM tag;")
    print(f"Total Tags: {tag_count}\n")
    
    # ========== SUMMARY ==========
    print("="*80)
    print("SUMMARY")
    print("-" * 80)
    print(f"  Users: {user_count}")
    print(f"  Notes: {note_count}")
    print(f"  Tags: {tag_count}")
    print("="*80 + "\n")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nError: {e}")
        print("Make sure Docker is running and the synapse_postgres container is up.")
        print("Run: docker-compose up -d")
