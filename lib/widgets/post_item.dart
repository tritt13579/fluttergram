import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostItem extends StatelessWidget {
  final Map<String, String> post;
  final bool isLiked;
  final bool showHeart;
  final VoidCallback onDoubleTap;
  final VoidCallback onLikeToggle;

  const PostItem({
    super.key,
    required this.post,
    required this.isLiked,
    required this.showHeart,
    required this.onDoubleTap,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(post['avatar']!),
          ),
          title: Text(post['username']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.more_vert),
        ),
        // Image with double-tap like
        _buildPostImage(),
        // Actions
        _buildActionBar(),
        // Caption
        _buildCaption(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPostImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onDoubleTap: onDoubleTap,
          child: Image.network(
            post['image']!,
            width: double.infinity,
            height: 350,
            fit: BoxFit.cover,
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: showHeart ? 1.0 : 0.0,
          child: const Icon(Icons.favorite, color: Colors.white, size: 100),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLikeToggle,
            child: Icon(
              isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
              size: 24,
              color: isLiked ? Colors.pinkAccent : null,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(FontAwesomeIcons.comment, size: 24),
          const SizedBox(width: 16),
          const Icon(FontAwesomeIcons.paperPlane, size: 24),
          const Spacer(),
          const Icon(FontAwesomeIcons.bookmark, size: 24),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${post['username']!} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: post['caption']),
          ],
        ),
      ),
    );
  }
}