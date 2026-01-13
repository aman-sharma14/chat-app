import 'package:flutter/material.dart';
import 'dart:async';
import '../network/socket_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Toggle between Login (true) and Register (false)
  bool _isLogin = true;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SocketService _socketService = SocketService();
  
  String _statusMessage = "";
  bool _isLoading = false;

  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _connectToServer();
    
    // Listen for auth responses
    _socketSubscription = _socketService.responses.listen((response) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (response['status'] == 'success') {
          // Only navigate if strictly a "Login successful" message.
          // This prevents picking up 'get_users' or message events intended for other screens.
          if (response['message'] == 'Login successful') {
             Navigator.pushReplacement(
               context, 
               MaterialPageRoute(builder: (_) => HomeScreen(username: response['username'] ?? _usernameController.text))
             );
          } else if (response['message'] == 'Registration successful') {
            _statusMessage = "Registration Success! Please Login.";
            _isLogin = true; 
          }
        } else {
          _statusMessage = response['message'] ?? "Unknown Error";
        }
      });
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    await _socketService.connect();
  }

  void _submit() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    final action = _isLogin ? "login" : "register";
    _socketService.sendRequest(action, {
      "username": username,
      "password": password,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(
                _isLogin ? "Welcome Back" : "Create Account",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              
              // Input Fields
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: "Username",
                          border: InputBorder.none,
                          icon: Icon(Icons.person),
                        ),
                      ),
                      const Divider(),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: InputBorder.none,
                          icon: Icon(Icons.key),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                  ),
                ),

              // Main Action Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isLogin ? "LOGIN" : "REGISTER", style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
              
              const SizedBox(height: 20),
              
              // Switch Toggle
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _statusMessage = "";
                  });
                },
                child: Text(
                  _isLogin ? "Don't have an account? Register" : "Already have an account? Login",
                  style: TextStyle(color: Colors.indigo[800]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
