import 'package:flutter/material.dart';
import 'dart:async';
import '../network/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String otherUser;

  const ChatScreen({super.key, required this.currentUser, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _socketService.getHistory(widget.otherUser);

    // Listen for incoming messages
    _socketSubscription = _socketService.responses.listen((response) {
      if (!mounted) return;
      print("ChatScreen Recv: $response"); // DEBUG LOG
      
      if (response['type'] == 'history') {
         // Load past messages
         if (response['messages'] != null) {
           setState(() {
             _messages.clear();
             for (var msg in response['messages']) {
               _messages.add({
                 "sender": msg['sender'],
                 "content": msg['content'],
                 "isMe": msg['sender'] == widget.currentUser,
               });
             }
           });
         }
      } else if (response['type'] == 'new_message') {
        // Check if the message is from the user we are currently chatting with
        if (response['sender'] == widget.otherUser) {
          setState(() {
            _messages.add({
              "sender": response['sender'],
              "content": response['content'],
              "isMe": false,
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Send to server
    _socketService.sendMessage(widget.otherUser, content);

    // Add to local list immediately (optimistic update)
    setState(() {
      _messages.add({
        "sender": widget.currentUser,
        "content": content,
        "isMe": true,
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
              ? const Center(child: Text("Say Hello! 👋"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['isMe'];
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          msg['content'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
