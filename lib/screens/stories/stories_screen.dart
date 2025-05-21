import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoriesScreen extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final String imageUrl;
  final DateTime postedDateTime;
  final bool isCurrentUser;
  final VoidCallback? onDelete;

  const StoriesScreen({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.imageUrl,
    required this.postedDateTime,
    this.isCurrentUser = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgoText = timeago.format(postedDateTime);

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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(timeAgoText,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.pause, color: Colors.white),
            const SizedBox(width: 10),
            if (isCurrentUser)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onSelected: (value)  {
                  if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xoá Story'),
                  ),
                ],
              )
            else
              const Icon(Icons.more_horiz, color: Colors.white),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 40,
            child: Column(
              children: const [
                Icon(Icons.favorite_border, color: Colors.white, size: 30),
                SizedBox(height: 20),
                Icon(Icons.send, color: Colors.white, size: 28),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: const [
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