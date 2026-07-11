import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme_tokens.dart';
import '../models/chat_message.dart';
import 'identity_avatar.dart';

class ChatMessageTile extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final ValueChanged<ChatMessage>? onAttachmentTap;

  const ChatMessageTile({
    super.key,
    required this.message,
    required this.isMine,
    this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bubbleColor =
        isMine ? cs.primaryContainer : cs.surfaceContainerHighest;
    final textColor = isMine ? cs.onPrimaryContainer : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            UserAvatar(
              photoBase64: message.senderPhotoBase64,
              gender: message.senderGender,
              radius: 17,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.52),
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        if (message.attachmentId != null) ...[
                          if (message.text.isNotEmpty)
                            const SizedBox(height: 8),
                          _AttachmentPreview(
                            message: message,
                            onTap: onAttachmentTap == null
                                ? null
                                : () => onAttachmentTap!(message),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('h:mm a').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 8),
            UserAvatar(
              photoBase64: message.senderPhotoBase64,
              gender: message.senderGender,
              radius: 17,
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;

  const _AttachmentPreview({required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEvent = message.attachmentType == 'event';
    final color = isEvent ? tokens.warning : tokens.info;
    final previewSurface = tokens.elevatedSurface.withValues(
      alpha: tokens.isDark ? 0.9 : 0.78,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: previewSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.border.withValues(alpha: tokens.isDark ? 0.72 : 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: tokens.isDark ? 0.2 : 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEvent ? Icons.event_rounded : Icons.chat_bubble_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.attachmentTitle ?? 'Shared item',
                    style: TextStyle(
                      color: tokens.textStrong,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((message.attachmentSubtitle ?? '').isNotEmpty)
                    Text(
                      message.attachmentSubtitle!,
                      style: TextStyle(
                        color: tokens.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
