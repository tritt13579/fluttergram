import 'package:flutter/material.dart';

class StoriesScreen extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final String imageUrl;
  final String postedTime;

  const StoriesScreen({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.imageUrl,
    this.postedTime = '8 hours ago',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(postedTime,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Spacer(),
            Icon(Icons.pause, color: Colors.white),
            SizedBox(width: 10),
            Icon(Icons.more_horiz, color: Colors.white),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Story image
          // Positioned.fill(
          //   child: Image.network(
          //     imageUrl,
          //     fit: BoxFit.cover,
          //   ),
          // ),

          // Action buttons
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 40,
            child: Column(
              children: [
                Icon(Icons.favorite_border, color: Colors.white, size: 30),
                SizedBox(height: 20),
                Icon(Icons.send, color: Colors.white, size: 28),
              ],
            ),
          ),

          // Comment box
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Comment',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Icon(Icons.favorite, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Icon(Icons.emoji_emotions_outlined,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
