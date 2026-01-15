import socket
import json
import time

HOST = '127.0.0.1'
PORT = 8080

def test_handshake():
    # Simulate Client A (Alice)
    alice_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    alice_sock.settimeout(5)
    # Note: Server uses SSL, so we should wrap, but for this raw test maybe we assume server cert is self-signed
    # and we just want to test logic. 
    # Wait, server enforces SSL. We need SSL context.
    import ssl
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    
    alice_conn = context.wrap_socket(alice_sock, server_hostname=HOST)
    try:
        alice_conn.connect((HOST, PORT))
        print("[Alice] Connected")
    except Exception as e:
        print(f"[Alice] Connection failed: {e}")
        return

    # Alice Registers with Key
    alice_pub_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAliceKey..."
    req = {
        "action": "register",
        "username": "alice",
        "password": "password123",
        "public_key": alice_pub_key
    }
    alice_conn.send(json.dumps(req).encode('utf-8'))
    resp = json.loads(alice_conn.recv(4096).decode('utf-8'))
    print(f"[Alice] Register Resp: {resp}")

    # Simulate Client B (Bob)
    bob_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    bob_conn = context.wrap_socket(bob_sock, server_hostname=HOST)
    bob_conn.connect((HOST, PORT))
    print("[Bob] Connected")

    # Bob Registers with Key
    bob_pub_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQBobKey..."
    req = {
        "action": "register",
        "username": "bob",
        "password": "password123",
        "public_key": bob_pub_key
    }
    bob_conn.send(json.dumps(req).encode('utf-8'))
    resp = json.loads(bob_conn.recv(4096).decode('utf-8'))
    print(f"[Bob] Register Resp: {resp}")

    # Bob Login
    req = {
        "action": "login",
        "username": "bob",
        "password": "password123"
    }
    bob_conn.send(json.dumps(req).encode('utf-8'))
    resp = json.loads(bob_conn.recv(4096).decode('utf-8'))
    print(f"[Bob] Login Resp: {resp}")

    # Bob asks for users
    req = {"action": "get_users"}
    bob_conn.send(json.dumps(req).encode('utf-8'))
    resp = json.loads(bob_conn.recv(4096).decode('utf-8'))
    print(f"[Bob] Users Resp: {resp}")
    
    users = resp.get("users", [])
    found_alice = False
    for u in users:
        if u['username'] == 'alice':
            found_alice = True
            if u['public_key'] == alice_pub_key:
                print("✅ SUCCESS: Bob received Alice's Public Key correctly.")
            else:
                print("❌ FAILURE: Alice's key mismatch.")
    
    if not found_alice:
         print("❌ FAILURE: Alice not found in user list.")

    alice_conn.close()
    bob_conn.close()

if __name__ == "__main__":
    test_handshake()
