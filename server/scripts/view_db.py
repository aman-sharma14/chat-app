import sqlite3
import os

DB_NAME = "chat_app.db"

def inspect_db():
    if not os.path.exists(DB_NAME):
        print(f"[!] Database {DB_NAME} not found.")
        return

    conn = sqlite3.connect(DB_NAME)
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
