import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import 'package:intl/intl.dart';

class MessageItem extends StatelessWidget {
  final MessageModel message;
  final bool isSender;
  final Map<String, String> reactionEmojiMap;
  final Function(List<String>, int) openImageFullScreen;

  const MessageItem({
    super.key,
    required this.message,
    required this.isSender,
    required this.reactionEmojiMap,
    required this.openImageFullScreen,
  });

  Widget _buildReactions() {
    if (message.reactions == null || message.reactions!.isEmpty) {
      return SizedBox.shrink();
    }

    final entries = message.reactions!.entries.toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: entries.map((e) {
          final emoji = reactionEmojiMap[e.value] ?? e.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(emoji, style: TextStyle(fontSize: 14)),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildImages() {
    if (message.images!.isEmpty) return SizedBox.shrink();

    if (message.images!.length == 1) {
      return GestureDetector(
        onTap: () => openImageFullScreen(message.images!, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(message.images!.first, width: 200, height: 200, fit: BoxFit.cover),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: message.images.length,
        itemBuilder: (context, index) {
          final url = message.images[index];
          return GestureDetector(
            onTap: () => openImageFullScreen(message.images, index),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, width: 150, height: 200, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(isSender ? 12 : 0),
      bottomRight: Radius.circular(isSender ? 0 : 12),
    );

    final formattedDate = DateFormat('hh:mm a, dd/MM/yyyy').format(message.timestamp);

    final senderDisplayName = isSender ? 'Bạn' : message.senderName;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isSender ? Colors.red.shade300 : Colors.grey.shade400,
          borderRadius: borderRadius,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderDisplayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                if (message.message.isNotEmpty)
                  Text(
                    message.message,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                if (message.message.isNotEmpty && message.images.isNotEmpty)
                  SizedBox(height: 8),
                _buildImages(),
                SizedBox(height: 10),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
                ),
              ],
            ),

            if (message.reactions != null && message.reactions!.isNotEmpty)
              Positioned(
                bottom: -20,
                right: -20,
                child: _buildReactions(),
              ),
          ],
        ),
      ),
    );
  }
}
