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
          final List<dynamic> usersData = response['users'];
          _users = usersData.map((u) {
             if (u is Map) {
                return u['username'] as String;
             }
             return u.toString();
          }).toList();
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

  Color _getAvatarColor(String username) {
    if (username.isEmpty) return Colors.indigo;
    final int hash = username.codeUnits.fold(0, (previous, current) => previous + current);
    final List<Color> colors = [
      Colors.indigo, Colors.blue, Colors.teal, Colors.green, 
      Colors.orange, Colors.deepOrange, Colors.red, Colors.pink, Colors.purple
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("Contacts", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87), 
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchUsers();
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent), 
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
                   const Icon(Icons.people_outline, size: 60, color: Colors.grey),
                   const SizedBox(height: 10),
                   const Text("No other users found.", style: TextStyle(color: Colors.grey)),
                   const SizedBox(height: 10),
                   ElevatedButton(onPressed: _fetchUsers, child: const Text("Refresh Directory"))
                 ],
               )
             )
           : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: _getAvatarColor(user),
                      child: Text(user[0].toUpperCase(), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    title: Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text("Tap to chat w/ $user"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            currentUser: widget.username, 
                            otherUser: user
                          )
                        )
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
