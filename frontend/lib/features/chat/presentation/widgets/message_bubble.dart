import 'package:flutter/material.dart';
import '../../domain/chat_message.dart';
import '../../../../core/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAi = message.sender == MessageSender.ai;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isAi ? 16 : 64,
          4,
          isAi ? 64 : 16,
          4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isAi ? AppColors.surface : AppColors.healthcarePrimary,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft:
                isAi ? const Radius.circular(4) : const Radius.circular(20),
            bottomRight:
                isAi ? const Radius.circular(20) : const Radius.circular(4),
          ),
          border: isAi ? Border.all(color: AppColors.border) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: textTheme.bodyLarge?.copyWith(
                color: isAi ? AppColors.textPrimary : Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: textTheme.labelLarge?.copyWith(
                fontSize: 10,
                color: isAi ? AppColors.textTertiary : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
