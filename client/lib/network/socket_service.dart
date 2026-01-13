import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../config.dart';

class SocketService {
  static const String _host = AppConfig.serverHost;
  static const int _port = AppConfig.serverPort;

  Socket? _socket;
  
  // Singleton instance
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Stream controller to let the UI know when a message arrives
  final _responseController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get responses => _responseController.stream;

  Future<void> connect() async {
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
          _responseController.add(response); // Send response to the UI
        },
        onError: (error) => print("Socket Error: $error"),
        onDone: () => print("Connection Closed"),
      );
    } catch (e) {
      print("Connection Failed: $e");
    }
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