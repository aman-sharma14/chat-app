import os


BASE_DIR = os.path.dirname(os.path.abspath(__file__))

CERTS_DIR = os.path.join(BASE_DIR, "certs")
DATA_DIR = os.path.join(BASE_DIR, "data")
SCRIPTS_DIR = os.path.join(BASE_DIR, "scripts")

CERT_FILE = os.path.join(CERTS_DIR, "server.crt")
KEY_FILE = os.path.join(CERTS_DIR, "server.key")
DB_NAME = os.path.join(DATA_DIR, "chat_app.db")

if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

# Network Configuration
HOST = '0.0.0.0'
PORT = 8080
