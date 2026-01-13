import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import '../network/socket_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocketService _socketService = SocketService();
  List<String> _users = [];
  bool _isLoading = true;

  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    
    // Listen for user list response
    _socketSubscription = _socketService.responses.listen((response) {
      if (!mounted) return;
      if (response['status'] == 'success' && response['users'] != null) {
        setState(() {
          _users = List<String>.from(response['users']);
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _fetchUsers() {
    _socketService.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"), 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchUsers();
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () {
               // In a real app, disconnect or clear session
               Navigator.pushReplacement(
                 context, 
                 MaterialPageRoute(builder: (_) => const LoginScreen())
               );
            }
          )
        ]
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _users.isEmpty 
           ? Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text("No other users found."),
                   const SizedBox(height: 10),
                   ElevatedButton(onPressed: _fetchUsers, child: const Text("Refresh"))
                 ],
               )
             )
           : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Text(user[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Tap to chat"),
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => ChatScreen(currentUser: widget.username, otherUser: user))
                    );
                  },
                );
              },
            ),
    );
  }
}
