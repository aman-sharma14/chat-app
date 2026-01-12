import 'dart:io';
import 'dart:convert';
import 'dart:async';

class SocketService {
  // Use 10.0.2.2 for Android Emulator to access the host machine's localhost.
  // If running on a real device, change this to your laptop's local IP (e.g., 192.168.1.x).
  static const String _host = '10.0.2.2'; 
  static const int _port = 8080;

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
      _socket = await Socket.connect(_host, _port, timeout: Duration(seconds: 5));
      print("✅ Connected to Server");

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