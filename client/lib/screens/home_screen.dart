import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Contacts"),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen())
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo[100],
              child: Text(
                username[0].toUpperCase(), 
                style: const TextStyle(fontSize: 40, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Hello, $username!", 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            const Text(
              "Select a contact to start chatting",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Placeholder for Contact List
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text("User ${index + 1}"),
                    subtitle: const Text("Online"),
                    onTap: () {
                      // TODO: Navigate to Chat Screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Chatting with User ${index + 1} coming soon!"))
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
