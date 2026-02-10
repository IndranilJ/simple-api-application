"""
Clear Database Script
Deletes all data from the Synapse database.

Usage:
    python scripts/clear_db.py
"""

import subprocess


def clear_database():
    """Delete all data from all tables."""
    print("\n" + "="*80)
    print("CLEARING SYNAPSE DATABASE")
    print("="*80 + "\n")
    
    # Delete in correct order to handle foreign key constraints
    tables = ['notetaglink', 'note', 'tag', '"user"']
    
    for table in tables:
        print(f"Truncating {table}...")
        cmd = [
            'docker', 'exec', 'synapse_postgres',
            'psql', '-U', 'synapse', '-d', 'synapse_db',
            '-c', f'TRUNCATE TABLE {table} CASCADE;'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"  [OK] {table} cleared")
        else:
            print(f"  [ERROR] Error clearing {table}: {result.stderr}")
    
    print("\n" + "="*80)
    print("DATABASE CLEARED SUCCESSFULLY!")
    print("="*80)
    print("\nYou can now register new users and create notes at http://localhost\n")


if __name__ == "__main__":
    response = input("WARNING: This will delete ALL data! Are you sure? (yes/no): ")
    if response.lower() == 'yes':
        clear_database()
    else:
        print("\nCancelled. No data was deleted.")
