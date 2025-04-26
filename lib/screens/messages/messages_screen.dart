import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/MessagesController.dart';
import 'ChatScreen.dart';
import 'new_message_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MessagesController>(
      init: MessagesController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(
                  'Tin nhắn',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_square),
                onPressed: () {
                  Get.to(() => NewMessageScreen());
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey.shade800,
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                  radius: 24,
                ),
                title: Text('Ghi chú của bạn', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Chia sẻ ghi chú', style: TextStyle(color: Colors.white54)),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => controller.changeTab(0),
                    child: Column(
                      children: [
                        Text(
                          'Tin nhắn',
                          style: TextStyle(
                            color: controller.selectedTab == 0 ? Colors.white : Colors.white60,
                            fontWeight: controller.selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (controller.selectedTab == 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 2,
                            width: 60,
                            color: Colors.pinkAccent,
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.changeTab(1),
                    child: Column(
                      children: [
                        Text(
                          'Tin nhắn đang chờ',
                          style: TextStyle(
                            color: controller.selectedTab == 1 ? Colors.white : Colors.white60,
                            fontWeight: controller.selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (controller.selectedTab == 1)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 2,
                            width: 100,
                            color: Colors.pinkAccent,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.selectedTab == 0) ...[
                        // if (controller.suggestions.isEmpty)
                        //   Center(
                        //     child: Padding(
                        //       padding: const EdgeInsets.symmetric(vertical: 50),
                        //       child: Text(
                        //         'Các đoạn chat sẽ hiển thị ở đây sau ',
                        //         textAlign: TextAlign.center,
                        //         style: TextStyle(color: Colors.white60),
                        //       ),
                        //     ),
                        //   )
                        // else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: controller.suggestions.length,
                          itemBuilder: (context, index) {
                            final user = controller.suggestions[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user['avatar']!),
                                radius: 24,
                              ),
                              title: Text(user['name']!),
                              subtitle: Text("Nhấn vào để chat"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(user: user),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Gợi ý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: controller.suggestions.length,
                          itemBuilder: (context, index) {
                            final user = controller.suggestions[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user['avatar']!),
                                radius: 24,
                              ),
                              title: Text(user['name']!),
                              subtitle: Text(user['username']!),
                              trailing: Icon(Icons.camera_alt_outlined, color: Colors.white54),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tài khoản nên theo dõi',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Xử lý Xem tất cả
                                },
                                child: Text('Xem tất cả', style: TextStyle(color: Colors.blueAccent)),
                              ),
                            ],
                          ),
                        ),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: controller.recommended.length,
                          itemBuilder: (context, index) {
                            final account = controller.recommended[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(account['avatar']!),
                                radius: 24,
                              ),
                              title: Text(account['name']!),
                              subtitle: Text(account['username']!),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.lightBlue,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () {
                                      // TODO: Xử lý nút Theo dõi
                                    },
                                    child: Text('Theo dõi',style: TextStyle(color: Colors.white),),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.white54),
                                    onPressed: () {
                                      controller.removeRecommended(index);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                      ] else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 50),
                            child: Text(
                              'Bạn không có tin nhắn đang chờ nào.',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
