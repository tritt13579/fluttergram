import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final Map<String, String> user;

  const ChatScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user['name']!),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user['avatar']!),
                  radius: 40,
                ),
                const SizedBox(height: 8),
                Text(user['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user['username']!, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('1 người theo dõi - 0 bài viết', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Bạn đã theo dõi tài khoản Instagram này từ năm 2025', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Xin chào!'),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Chào bạn!', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhắn tin...',
                    filled: true,
                    fillColor: Colors.white12,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: Gửi tin nhắn
                },
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(12),
                  backgroundColor: Colors.blue,
                ),
                child: Icon(Icons.send, size: 24, color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}
