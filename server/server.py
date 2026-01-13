import socket
import threading
import json
import ssl
import database_handler
import config

# Handles the lifecycle of a single client connection
def handle_client(conn, addr):
    print(f"[*] Connection established: {addr}")
    
    while True:
        try:
            # Buffer size 1024 bytes; decode from UTF-8 string
            raw_data = conn.recv(1024).decode('utf-8')
            if not raw_data:
                break
            
            # Parse incoming JSON request
            request = json.loads(raw_data)
            action = request.get("action")

            if action == "register":
                username = request.get("username")
                password = request.get("password")
                
                # Check if the user sent both username and password
                if not username or not password:
                    response = {"status": "error", "message": "Missing credentials"}
                else:
                    # Attempt to register in the database
                    success = database_handler.add_user(username, password)
                    if success:
                        print(f"[AUTH] Registered new user: {username}")
                        response = {"status": "success", "message": "Registration successful"}
                    else:
                        response = {"status": "error", "message": "Username already exists"}
                
                conn.send(json.dumps(response).encode('utf-8'))

            elif action == "login":
                username = request.get("username")
                password = request.get("password")
                
                # Fetch user from DB to verify password
                user_record = database_handler.get_user(username)
                
                if user_record and database_handler.verify_password(user_record[1], password):
                    print(f"[AUTH] User successfully logged in: {username}")
                    # In a real app, we would store the session/connection here to route messages later.
                    response = {"status": "success", "message": "Login successful", "username": username}
                else:
                    print(f"[AUTH] Failed login attempt for: {username}")
                    response = {"status": "error", "message": "Invalid username or password"}
                
                conn.send(json.dumps(response).encode('utf-8'))

        except Exception as e:
            print(f"[!] Error with client {addr}: {e}")
            break

    conn.close()
    print(f"[*] Connection closed: {addr}")

# Main listener loop
def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    # Allow local network connections
    server.bind((config.HOST, config.PORT)) 
    server.listen(5)
    
    print(f"[+] Server listening on port {config.PORT} (SSL/TLS Enabled)...")
    print(f"[i] Loading certs from: {config.CERTS_DIR}")

    # Create SSL Context
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    try:
        context.load_cert_chain(certfile=config.CERT_FILE, keyfile=config.KEY_FILE)
    except FileNotFoundError:
        print("[!] Error: Certificates not found! Please run 'python server/scripts/generate_cert.py'")
        return
    
    while True:
        try:
            # Accept the raw connection first
            client_sock, addr = server.accept()
            
            # Wrap the socket with SSL
            # server_side=True means we are the server
            conn = context.wrap_socket(client_sock, server_side=True)
            
            # Spin up a new thread for each concurrent user
            threading.Thread(target=handle_client, args=(conn, addr)).start()
        except Exception as e:
            print(f"[!] TLS Handshake failed: {e}")

if __name__ == "__main__":
    database_handler.init_db()
    start_server()