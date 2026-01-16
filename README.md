# Secure Chat Application 🔒📱

A robust, full-stack chat application featuring a Python TCP/SSL Server and a Flutter Mobile Client, communicating via encrypted sockets.

## 📌 Project Overview
This project fulfills the Network Security assignment requirements by implementing a secure, database-backed communication system. It demonstrates mastery of low-level socket programming, database management, and mobile application development.

### Core Features
- **Python Socket Server**: Multi-threaded TCP server handling real-time connections.
- **SQLite Database**: Persistent storage for users and message history.
- **Mobile Client**: Cross-platform app built with Flutter (tested on Android).
- **Security**: 
  - **SSL/TLS**: Encrypted transport layer using `ssl` module and `SecureSocket`.
  - **E2EE**: End-to-End Encryption using Hybrid RSA+AES scheme.
  - **Auth**: Secure password hashing with `bcrypt`.

---

## 🛠️ Architecture

### Server (`/server`)
The backend is a pure Python implementation without heavy web frameworks, ensuring performant raw socket communication.
- `server.py`: Main entry point. Initializes SSL context, binds to port `8080`, and manages client threads. It acts as a Zero-Knowledge router for E2EE messages.
- `database_handler.py`: Manages the SQLite connection. Handles user registration, authentication, and encrypted message persistence.
- `config.py`: Centralized configuration for Environment paths and Network settings.

### Client (`/client`)
The frontend is a Flutter application focusing on a clean UI and robust security logic.
- **Networking**: `SocketService` uses Dart's `SecureSocket` to establish a persistent TLS connection.
- **Crypto**: `CryptoUtils` handles client-side key generation (RSA-2048) and message encryption (AES-256-CBC).
- **UI**: 
  - `LoginScreen`: Unified Login/Register flow.
  - `HomeScreen`: Real-time contact list with dynamic avatars.
  - `ChatScreen`: Modern chat interface with bubbles, timestamps, and optimistic updates.

---

## 🔒 End-to-End Encryption (E2EE) Logic

We implemented a Hybrid Encryption Scheme where the server acts only as a directory for Public Keys and a store for encrypted blobs. The server **cannot** read the messages.

1.  **Key Generation**: Upon install, the client generates an **RSA-2048 KeyPair**. The Private Key is stored in the device's secure storage; the Public Key is sent to the server on registration.
2.  **Key Exchange**: When User A wants to chat with User B, the client fetches User B's Public Key from the server.
3.  **Message Protocol**:
    *   client generates a fresh **AES-256 Key (K)** and **IV**.
    *   Message text is encrypted with `AES-CBC(K, IV)`.
    *   `K` is encrypted with Recipient's Public Key (Key Encapsulation).
    *   `K` is *also* encrypted with Sender's Public Key (so the sender can read their own history).
4.  **Payload**: The server receives and stores a JSON payload containing the encrypted content and the map of encrypted keys.

---

## 📦 Setup Instructions

### 1. Server Setup
**Prerequisites**: Python 3.8+

1. Navigate to the server directory:
   ```bash
   cd server
   ```
2. Run the server:
   ```bash
   python server.py
   ```
   *The server will start listening on `0.0.0.0:8080`.*
   *Note: Using self-signed certificates in `certs/`.*

### 2. Client Setup
**Prerequisites**: Flutter SDK, Android Studio (Emulator)

1. Navigate to the client directory:
   ```bash
   cd client
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on Emulator:
   ```bash
   flutter run
   ```
   *Tip: To test with two users, launch two emulators and run `flutter run -d <emulator_id>` for each.*


