import sqlite3
import bcrypt
import config

def init_db():
    """
    Sets up the database tables if they don't exist yet.
    We need one table for users and another one for storing messages.
    """
    conn = sqlite3.connect(config.DB_NAME)
    cursor = conn.cursor()

    # Users table
    cursor.execute('''CREATE TABLE IF NOT EXISTS users 
                      (username TEXT PRIMARY KEY, password_hash TEXT)''')

    # Messages Table
    cursor.execute('''CREATE TABLE IF NOT EXISTS messages 
                      (id INTEGER PRIMARY KEY AUTOINCREMENT, 
                       sender TEXT, receiver TEXT, content TEXT, 
                       timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')
    conn.commit()
    conn.close()

def hash_password(password: str):
    # Securely hash the password using a salt so it's not plain text.
    byte_pwd = password.encode('utf-8')
    pwd_hash = bcrypt.hashpw(byte_pwd, bcrypt.gensalt(rounds=12))
    return pwd_hash.decode('utf-8')

def verify_password(stored_hash: str, provided_password: str):
    # Check if the password user sent matches the hash we have in DB.
    return bcrypt.checkpw(provided_password.encode('utf-8'), stored_hash.encode('utf-8'))

def add_user(username, password):
    """
    Tries to register a new user.
    Returns True if successful, False if the username is already taken.
    """
    hashed = hash_password(password)
    try:
        conn = sqlite3.connect(config.DB_NAME)
        cursor = conn.cursor()
        cursor.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", (username, hashed))
        conn.commit()
        return True
    except sqlite3.IntegrityError:
        # This happens if the username already exists in the database
        return False
    finally:
        conn.close()

def get_user(username):
    """
    Fetches user info from the database to check login details.
    """
    conn = sqlite3.connect(config.DB_NAME)
    cursor = conn.cursor()
    cursor.execute("SELECT username, password_hash FROM users WHERE username = ?", (username,))
    user = cursor.fetchone()
    conn.close()
    return user

def get_all_users(exclude_username):
    """
    Returns a list of all registered usernames, except the requester.
    """
    conn = sqlite3.connect(config.DB_NAME)
    cursor = conn.cursor()
    cursor.execute("SELECT username FROM users WHERE username != ?", (exclude_username,))
    users = [row[0] for row in cursor.fetchall()]
    conn.close()
    return users

def store_message(sender, receiver, content):
    # Log the message to the database for history/persistence.
    conn = sqlite3.connect(config.DB_NAME)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO messages (sender, receiver, content) VALUES (?, ?, ?)", 
                   (sender, receiver, content))
    conn.commit()
    conn.close()

def get_chat_history(user1, user2):
    """
    Retrieves all messages between user1 and user2, sorted by time.
    """
    conn = sqlite3.connect(config.DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT sender, content FROM messages 
        WHERE (sender = ? AND receiver = ?) OR (sender = ? AND receiver = ?)
        ORDER BY timestamp ASC
    """, (user1, user2, user2, user1))
    
    messages = [{"sender": row[0], "content": row[1]} for row in cursor.fetchall()]
    conn.close()
    return messages

if __name__ == "__main__":
    init_db()
    print("Database initialized and ready to go.")