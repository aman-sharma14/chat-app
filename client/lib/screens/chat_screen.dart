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
                 "timestamp": msg['timestamp'], 
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
              "timestamp": response['timestamp'],
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
        "timestamp": DateTime.now().toIso8601String(),
        "isMe": true,
      });
      _messageController.clear();
    });
  }
  
  String _formatTime(String? isoString) {
    if (isoString == null) return "";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      
      // Check if the date is today
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      
      if (isToday) {
        return "$hour:$minute";
      } else {
        return "${dt.month}/${dt.day} $hour:$minute";
      }
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // Light grey background
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo,
              child: Text(widget.otherUser.isNotEmpty ? widget.otherUser[0].toUpperCase() : "?", 
                style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUser),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("Say Hello to ${widget.otherUser}! 👋", style: const TextStyle(color: Colors.grey)),
                    ],
                  )
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['isMe'];
                    final time = _formatTime(msg['timestamp']);
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.indigoAccent : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 2),
                                  blurRadius: 2,
                                )
                              ],
                            ),
                            child: Text(
                              msg['content'],
                              style: TextStyle(
                                fontSize: 16,
                                color: isMe ? Colors.white : Colors.black87
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
                            child: Text(
                              time,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 4)]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
