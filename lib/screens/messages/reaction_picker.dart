import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Map<String, String> reactionEmojiMap;
  final void Function(String) onReactionSelected;

  const ReactionPicker({
    super.key,
    required this.reactionEmojiMap,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final keys = reactionEmojiMap.keys.toList();
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          final emoji = reactionEmojiMap[key]!;
          return GestureDetector(
            onTap: () => onReactionSelected(key),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
