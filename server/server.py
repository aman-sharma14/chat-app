import socket
import threading
import json
import ssl
import datetime
import database_handler
import config

# Global dictionary to map username -> socket_connection
# This allows us to find the right socket when A wants to message B.
connected_clients = {}

# Handles the lifecycle of a single client connection
def handle_client(conn, addr):
    print(f"[*] Connection established: {addr}")
    current_username = None
    
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
                public_key = request.get("public_key")
                
                if not username or not password or not public_key:
                    response = {"status": "error", "message": "Missing credentials or public key"}
                else:
                    success = database_handler.add_user(username, password, public_key)
                    if success:
                        print(f"[AUTH] Registered new user: {username}")
                        response = {"status": "success", "message": "Registration successful"}
                    else:
                        response = {"status": "error", "message": "Username already exists"}
                
                conn.send(json.dumps(response).encode('utf-8'))

            elif action == "login":
                username = request.get("username")
                password = request.get("password")
                
                user_record = database_handler.get_user(username)
                
                if user_record and database_handler.verify_password(user_record[1], password):
                    print(f"[AUTH] User successfully logged in: {username}")
                    
                    # 1. Store the connection in our global dictionary
                    connected_clients[username] = conn
                    current_username = username
                    
                    response = {"status": "success", "message": "Login successful", "username": username}
                else:
                    print(f"[AUTH] Failed login attempt for: {username}")
                    response = {"status": "error", "message": "Invalid username or password"}
                
                conn.send(json.dumps(response).encode('utf-8'))

            elif action == "get_users":
                # Return list of all users so we can choose who to chat with
                if current_username:
                    users = database_handler.get_all_users(exclude_username=current_username)
                    response = {"status": "success", "users": users}
                    conn.send(json.dumps(response).encode('utf-8'))

            elif action == "get_history":
                other_user = request.get("with")
                if current_username and other_user:
                    messages = database_handler.get_chat_history(current_username, other_user)
                    response = {
                        "status": "success", 
                        "type": "history",
                        "messages": messages
                    }
                    conn.send(json.dumps(response).encode('utf-8'))

            elif action == "send_message":
                receiver = request.get("to")
                content = request.get("content")
                
                if current_username and receiver and content:
                    print(f"[MSG] {current_username} -> {receiver}: {content}")
                    
                    # 1. Save to Database (Persistent Storage)
                    database_handler.store_message(current_username, receiver, content)
                    
                    # 2. Forward to Receiver (Real-time Delivery)
                    if receiver in connected_clients:
                        receiver_conn = connected_clients[receiver]
                        try:
                            # Send a JSON packet to the receiver
                            msg_packet = {
                                "type": "new_message",
                                "sender": current_username,
                                "content": content,
                                "timestamp": datetime.datetime.now().isoformat() 
                            }
                            receiver_conn.send(json.dumps(msg_packet).encode('utf-8'))
                        except Exception as e:
                            print(f"[!] Failed to send to {receiver}: {e}")
                            # Maybe remove them from connected_clients if socket is dead?
                    
                    response = {"status": "success"}
                    conn.send(json.dumps(response).encode('utf-8'))

        except Exception as e:
            print(f"[!] Error with client {addr}: {e}")
            break

    # Cleanup when user disconnects
    if current_username and current_username in connected_clients:
        del connected_clients[current_username]
        print(f"[*] User disconnected: {current_username}")
    
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