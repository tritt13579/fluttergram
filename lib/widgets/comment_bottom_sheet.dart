import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../controllers/home_controller.dart';
import '../models/comment_model.dart';

class CommentBottomSheet extends StatelessWidget {
  final String postId;
  final HomeController controller;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.controller,
  });

  static Future<void> show({
    required BuildContext context,
    required String postId,
    required HomeController controller,
  }) {
    return showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        postId: postId,
        controller: controller,
      ),
      enableDrag: true,
      expand: false,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCommentsList()),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: const Center(
        child: Text(
          'Bình luận',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return Obx(() {
      if (controller.isLoadingComments.value && controller.comments.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.comments.isEmpty) {
        return Center(
          child: Text(
            'Chưa có bình luận nào',
            style: TextStyle(color: Colors.grey[400]),
          ),
        );
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo is ScrollEndNotification) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
              controller.loadMoreComments(postId);
            }
          }
          return false;
        },
        child: ListView.builder(
          itemCount: controller.comments.length + (controller.hasMoreComments.value ? 1 : 0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemBuilder: (context, index) {
            if (index == controller.comments.length) {
              return Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            }

            final comment = controller.comments[index];
            return _buildCommentItem(comment);
          },
        ),
      );
    });
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.userAvatar != null
                ? NetworkImage(comment.userAvatar!)
                : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: comment.username ?? 'Người dùng',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: ' ${comment.text}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(comment.createdAt, locale: 'vi'),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          Obx(() {
            String avatarUrl = 'assets/images/default_avatar.jpg';
            if (controller.currentUser.value?.avatar != null) {
              avatarUrl = controller.currentUser.value!.avatar;
            }
            return CircleAvatar(
              radius: 18,
              backgroundImage: avatarUrl.startsWith('http')
                  ? NetworkImage(avatarUrl)
                  : AssetImage(avatarUrl) as ImageProvider,
            );
          }),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.commentController,
              decoration: InputDecoration(
                hintText: 'Thêm bình luận...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                filled: true,
                fillColor: Colors.grey[900],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.pinkAccent),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => controller.addComment(postId),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}