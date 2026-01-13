import socket
import ssl
import sys

# Adjust path to import config if needed, or just hardcode for this simple script
HOST = '127.0.0.1'
PORT = 8080

def verify_ssl_connection():
    print(f"[*] Attempting to connect to {HOST}:{PORT}...")
    
    # Create a raw socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    
    # Wrap it with SSL context
    # output_format puts it in a nice readable format
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE # don't have the CA trusted locally, just want to fetch it

    try:
        wrapped_sock = context.wrap_socket(sock, server_hostname="localhost")
        wrapped_sock.connect((HOST, PORT))
        
        print(f"[+] Connection Successful!")
        print(f"[+] Cipher: {wrapped_sock.cipher()}")
        print(f"[+] Protocol: {wrapped_sock.version()}")
        
        cert = wrapped_sock.getpeercert(binary_form=True)
        if cert:
            print("[+] Certificate received from server (Binary blob present)")
            print("    Your server is definitively using SSL/TLS.")
        else:
            print("[-] No certificate received.")

        wrapped_sock.close()
        
    except Exception as e:
        print(f"[!] Connection failed: {e}")
        print("    (Make sure server.py is running!)")

if __name__ == "__main__":
    verify_ssl_connection()
