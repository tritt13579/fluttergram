import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../models/post_model.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../screens/home/edit_post_screen.dart';

class PostItem extends StatelessWidget {
  final PostModel post;
  final bool isLiked;
  final bool showHeart;
  final VoidCallback onDoubleTap;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onProfileTap;
  final RxBool _isExpanded = false.obs;

  PostItem({
    super.key,
    required this.post,
    required this.isLiked,
    required this.showHeart,
    required this.onDoubleTap,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildPostMedia(),
        _buildActionBar(),
        _buildCaption(),
        _buildTimestamp(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 20,
              backgroundImage: post.ownerPhotoUrl != null
                  ? NetworkImage(post.ownerPhotoUrl!)
                  : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Text(
                post.ownerUsername ?? 'Người dùng',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPostOptions(Get.context!),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    final currentUserId = Get.find<HomeController>().currentUserId;
    final isOwner = currentUserId == post.ownerId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text('Chỉnh sửa bài viết', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _editPost(context);
                  },
                ),
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.white),
                  title: const Text('Xóa bài viết', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text('Chia sẻ', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.white),
                title: const Text('Đóng', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editPost(BuildContext context) {
    Get.to(() => EditPostScreen(post: post));
  }

  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Xóa bài viết', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Bạn có chắc chắn muốn xóa bài viết này không?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Get.find<HomeController>().deletePost(post.id);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostMedia() {
    if (post.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    if (post.mediaUrls.length == 1) {
      return _buildSingleMedia(post.mediaUrls.first);
    } else {
      return _buildMediaCarousel();
    }
  }

  Widget _buildSingleMedia(String mediaUrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onDoubleTap: onDoubleTap,
          child: Image.network(
            mediaUrl,
            width: double.infinity,
            height: 350,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: 350,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => SizedBox(
              height: 350,
              child: Center(
                child: Icon(Icons.error, size: 40, color: Colors.grey[400]),
              ),
            ),
          ),
        ),
        IgnorePointer(
          ignoring: true,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: showHeart ? 1.0 : 0.0,
            child: const Icon(Icons.favorite, color: Colors.white, size: 100),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCarousel() {
    return SizedBox(
      height: 350,
      child: PageView.builder(
        itemCount: post.mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onDoubleTap: onDoubleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  post.mediaUrls[index],
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.error, size: 40, color: Colors.grey[400]),
                  ),
                ),
                if (showHeart)
                  const Icon(Icons.favorite, color: Colors.white, size: 100),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.7 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}/${post.mediaUrls.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onLikeToggle,
                child: Icon(
                  isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                  size: 24,
                  color: isLiked ? Colors.pinkAccent : null,
                ),
              ),
              if (post.likeCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    post.likeCount.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: isLiked ? Colors.pinkAccent : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              GestureDetector(
                onTap: onCommentTap,
                child: const Icon(FontAwesomeIcons.comment, size: 24),
              ),
              if (post.commentCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    post.commentCount.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          const Icon(FontAwesomeIcons.paperPlane, size: 24),
          const Spacer(),
          const Icon(FontAwesomeIcons.bookmark, size: 24),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    if (post.caption.isEmpty) return const SizedBox.shrink();

    final captionText = TextSpan(
      children: [
        TextSpan(
          text: '${post.ownerUsername ?? 'Người dùng'} ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        TextSpan(
            text: post.caption,
            style: const TextStyle(fontSize: 16)
        ),
      ],
    );

    final textPainter = TextPainter(
      text: captionText,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );

    textPainter.layout(maxWidth: Get.width - 32);

    final exceedMaxLines = textPainter.didExceedMaxLines;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => RichText(
            maxLines: _isExpanded.value ? null : 2,
            overflow: _isExpanded.value ? TextOverflow.visible : TextOverflow.ellipsis,
            text: captionText,
          )),

          if (exceedMaxLines)
            Obx(() => _isExpanded.value
                ? GestureDetector(
              onTap: () => _isExpanded.value = false,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ẩn bớt',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
                : GestureDetector(
              onTap: () => _isExpanded.value = true,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Xem thêm',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    if (post.createdAt == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        timeago.format(post.createdAt!, locale: 'vi'),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }
}