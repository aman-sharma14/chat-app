import sqlite3
import os
import sys

# Add parent directory to path to import config
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import config

def inspect_db():
    print(f"[*] Inspecting database at: {config.DB_NAME}")
    if not os.path.exists(config.DB_NAME):
        print(f"[!] Database not found at {config.DB_NAME}")
        return

    conn = sqlite3.connect(config.DB_NAME)
    cursor = conn.cursor()

    print("\n--- USERS ---")
    try:
        cursor.execute("SELECT * FROM users")
        users = cursor.fetchall()
        for u in users:
            print(f"Username: {u[0]} | Hash: {u[1][:15]}...") 
    except Exception as e:
        print(f"Error reading users: {e}")

    print("\n--- MESSAGES ---")
    try:
        cursor.execute("SELECT * FROM messages")
        msgs = cursor.fetchall()
        if not msgs:
            print("(No messages yet)")
        for m in msgs:
            print(m)
    except Exception as e:
        print(f"Error reading messages: {e}")

    conn.close()

if __name__ == "__main__":
    inspect_db()
