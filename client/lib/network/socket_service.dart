import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../config.dart';
import '../utils/crypto_utils.dart';

class SocketService {
  static const String _host = AppConfig.serverHost;
  static const int _port = AppConfig.serverPort;

  Socket? _socket;
  final Map<String, String> _userKeys = {}; // Cache for public keys
  String? _currentUser;

  
  // Singleton instance
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Stream controller to let the UI know when a message arrives
  final _responseController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get responses => _responseController.stream;

  Future<void> connect() async {
    await CryptoUtils().init(); // Initialize keys
    try {
      // Connect using SSL/TLS (SecureSocket)
      // onBadCertificate: (cert) => true allows us to use our self-signed certificate
      _socket = await SecureSocket.connect(
        _host, 
        _port, 
        onBadCertificate: (X509Certificate cert) => true,
        timeout: const Duration(seconds: 5)
      );
      print("✅ Connected to Server (Secure)");

      _socket?.listen(
        (List<int> data) {
          final String decoded = utf8.decode(data);
          final Map<String, dynamic> response = jsonDecode(decoded);
          
          // Handle intercepting data for E2EE
          _handleResponse(response);
          
          _responseController.add(response); // Send response to the UI
        },
        onError: (error) => print("Socket Error: $error"),
        onDone: () => print("Connection Closed"),
      );
    } catch (e) {
      print("Connection Failed: $e");
    }
  }

  void getUsers() {
    sendRequest("get_users", {});
  }

  void getHistory(String withUser) {
    sendRequest("get_history", {
      "with": withUser,
    });
  }

  void sendMessage(String to, String content) {
    // Encrypt content
    final receiverKey = _userKeys[to];
    if (receiverKey == null) {
      print("Error: Public Key for $to not found. Cannot encrypt.");
      return;
    }
    
    final encryptedContent = CryptoUtils().encryptMessage(content, receiverKey);

    sendRequest("send_message", {
      "to": to,
      "content": encryptedContent,
    });
  }

  void _handleResponse(Map<String, dynamic> response) {
      final status = response['status'];
      final type = response['type']; // 'new_message' or 'history' usually came with status? 
      // Actually 'new_message' packet in server.py (line 98) doesn't have 'status' key, directly 'type'.
      // Wait, server code: socket.send for 'new_message' is: {"type": "new_message", ...}
      
      // Let's check type first
      if (response.containsKey('type') && response['type'] == 'new_message') {
          // Decrypt
          final encryptedContent = response['content'];
          response['content'] = CryptoUtils().decryptMessage(encryptedContent);
      }
      
      if (status == 'success') {
          if (response.containsKey('users')) {
             // Update Key Cache from get_users
             // Response: "users": [{"username": "alice", "public_key": "..."}]
             final List<dynamic> users = response['users'];
             for (var u in users) {
                 if (u is Map) {
                     _userKeys[u['username']] = u['public_key'];
                 }
             }
          }
          
          if (response.containsKey('type') && response['type'] == 'history') {
              // Decrypt history messages
              final List<dynamic> messages = response['messages'];
              for (var msg in messages) {
                  final sender = msg['sender'];
                  final encryptedContent = msg['content'];
                  // If I sent it, isMyMessage=true
                  final isMe = (sender == _currentUser);
                  msg['content'] = CryptoUtils().decryptMessage(encryptedContent, isMyMessage: isMe);
              }
          }
           
          // Update current user on login
          if (response.containsKey('username')) {
             _currentUser = response['username'];
          }
      }
  }

  void register(String username, String password) {
      sendRequest("register", {
          "username": username,
          "password": password,
          "public_key": CryptoUtils().getMyPublicKeyPem(),
      });
  }

  void login(String username, String password) {
      sendRequest("login", {
          "username": username,
          "password": password,
      });
  }

  void sendRequest(String action, Map<String, dynamic> data) {
    if (_socket != null) {
      final request = {
        "action": action,
        ...data,
      };
      _socket!.write(jsonEncode(request));
    }
  }

  void dispose() {
    _socket?.destroy();
    _responseController.close();
  }
}