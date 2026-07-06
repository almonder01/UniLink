import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/club.dart';
import '../../models/club_room.dart';
import '../../models/direct_chat.dart';
import '../../models/event.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../providers/club_provider.dart';
import '../../services/club_membership_service.dart';
import '../../services/club_room_service.dart';
import '../../services/direct_chat_service.dart';

class ShareToChatSheet extends StatelessWidget {
  final String attachmentType;
  final String attachmentId;
  final String attachmentTitle;
  final String attachmentSubtitle;
  final String attachmentClubId;
  final UserModel user;

  const ShareToChatSheet({
    super.key,
    required this.attachmentType,
    required this.attachmentId,
    required this.attachmentTitle,
    required this.attachmentSubtitle,
    required this.attachmentClubId,
    required this.user,
  });

  static Future<void> showPost(
    BuildContext context, {
    required PostModel post,
    required UserModel user,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShareToChatSheet(
        attachmentType: 'post',
        attachmentId: post.id,
        attachmentTitle: post.title,
        attachmentSubtitle: post.clubName,
        attachmentClubId: post.clubId,
        user: user,
      ),
    );
  }

  static Future<void> showEvent(
    BuildContext context, {
    required EventModel event,
    required UserModel user,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ShareToChatSheet(
        attachmentType: 'event',
        attachmentId: event.id,
        attachmentTitle: event.title,
        attachmentSubtitle: event.clubName,
        attachmentClubId: event.clubId,
        user: user,
      ),
    );
  }

  Future<_ShareTargets> _loadTargets(List<ClubModel> clubs) async {
    final membershipService = ClubMembershipService();
    final roomService = ClubRoomService();
    final directService = DirectChatService();

    final clubIds = (await membershipService.memberClubIdsForUser(user.id))
        .toSet();
    if ((user.managedClubId ?? '').isNotEmpty) clubIds.add(user.managedClubId!);

    final rooms = await roomService.roomsForClubIds(clubIds.toList());
    final directChats = await directService.chatsForUser(user.id);
    final clubNames = {
      for (final club in clubs) club.id: club.name,
    };
    return _ShareTargets(
      rooms: rooms,
      directChats: directChats,
      clubNames: clubNames,
    );
  }

  Future<void> _sendToRoom(BuildContext context, ClubRoom room) async {
    await ClubRoomService().sendMessage(
      roomId: room.id,
      sender: user,
      text: attachmentType == 'event' ? 'Shared an event' : 'Shared a post',
      attachmentType: attachmentType,
      attachmentId: attachmentId,
      attachmentTitle: attachmentTitle,
      attachmentSubtitle: attachmentSubtitle,
      attachmentClubId: attachmentClubId,
    );
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shared to room.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendToDirect(BuildContext context, DirectChat chat) async {
    await DirectChatService().sendMessage(
      chatId: chat.id,
      sender: user,
      text: attachmentType == 'event' ? 'Shared an event' : 'Shared a post',
      attachmentType: attachmentType,
      attachmentId: attachmentId,
      attachmentTitle: attachmentTitle,
      attachmentSubtitle: attachmentSubtitle,
      attachmentClubId: attachmentClubId,
    );
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shared to chat.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clubs = context.watch<ClubProvider>().clubs;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: FutureBuilder<_ShareTargets>(
          future: _loadTargets(clubs),
          builder: (context, snapshot) {
            final targets = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share to chat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  attachmentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (targets == null ||
                    (targets.rooms.isEmpty && targets.directChats.isEmpty))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'No rooms or private chats available yet',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.48),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (targets.rooms.isNotEmpty) ...[
                    const _SheetLabel('Club Rooms'),
                    const SizedBox(height: 8),
                    ...targets.rooms.map(
                      (room) => _TargetTile(
                        icon: Icons.forum_rounded,
                        title: room.name,
                        subtitle: targets.clubNames[room.clubId] ?? 'Club room',
                        onTap: () => _sendToRoom(context, room),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (targets.directChats.isNotEmpty) ...[
                    const _SheetLabel('Private Chats'),
                    const SizedBox(height: 8),
                    ...targets.directChats.map(
                      (chat) => _TargetTile(
                        icon: Icons.mark_chat_unread_rounded,
                        title: chat.otherName(user.id),
                        subtitle: chat.lastMessage.isEmpty
                            ? 'Private message'
                            : chat.lastMessage,
                        onTap: () => _sendToDirect(context, chat),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShareTargets {
  final List<ClubRoom> rooms;
  final List<DirectChat> directChats;
  final Map<String, String> clubNames;

  const _ShareTargets({
    required this.rooms,
    required this.directChats,
    required this.clubNames,
  });
}

class _SheetLabel extends StatelessWidget {
  final String label;

  const _SheetLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TargetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: cs.primary, size: 19),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.send_rounded, size: 18),
      ),
    );
  }
}
