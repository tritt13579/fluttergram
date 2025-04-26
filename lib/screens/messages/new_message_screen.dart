import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'new_group_screen.dart';

class NewMessageScreen extends StatelessWidget {
  const NewMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tin nhắn mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Đến: Tìm kiếm',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[700],
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: Text('Tạo nhóm chat'),
              onTap: () {
                Get.to(() => NewGroupScreen());
              },
            ),
            const SizedBox(height: 16),
            Text('Gợi ý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=$index'),
                    ),
                    title: Text('Tên người dùng $index'),
                    subtitle: Text('username$index'),
                    onTap: () {
                      // TODO: Khi bấm vào 1 user
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
