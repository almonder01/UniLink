import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../models/club_room.dart';
import '../../models/event.dart';
import '../../models/user.dart';
import '../../services/club_room_service.dart';
import '../../services/event_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/base64_image.dart';
import 'club_room_dashboard_screen.dart';
import 'club_room_chat_screen.dart';

part 'room_settings/room_event_invite_sheet.dart';
part 'room_settings/room_invite_dialog.dart';
part 'room_settings/room_name_dialog.dart';

class ClubRoomSettingsScreen extends StatefulWidget {
  final ClubModel club;
  final UserModel user;

  const ClubRoomSettingsScreen({
    super.key,
    required this.club,
    required this.user,
  });

  @override
  State<ClubRoomSettingsScreen> createState() => _ClubRoomSettingsScreenState();
}

class _ClubRoomSettingsScreenState extends State<ClubRoomSettingsScreen> {
  final _service = ClubRoomService();

  bool get _isManager => widget.user.id == widget.club.managerId;

  Future<void> _createRoom() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _RoomNameDialog(),
    );
    if (!mounted) return;
    if (name == null || name.trim().isEmpty) return;
    await _service.createRoom(
      clubId: widget.club.id,
      name: name.trim(),
      createdBy: widget.user.id,
    );
  }

  Future<void> _invite(ClubRoom room) async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _RoomInviteDialog(roomName: room.name),
    );
    if (!mounted) return;
    if (email == null || email.trim().isEmpty) return;

    try {
      await _service.inviteByEmail(
        club: widget.club,
        room: room,
        sender: widget.user,
        email: email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _inviteEventGroup(ClubRoom room) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RoomEventInviteSheet(
        club: widget.club,
        room: room,
        sender: widget.user,
      ),
    );
  }

  void _openRoom(ClubRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubRoomChatScreen(
          room: room,
          club: widget.club,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Settings'),
        actions: [
          if (_isManager)
            IconButton(
              tooltip: 'Room dashboard',
              icon: const Icon(Icons.dashboard_customize_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClubRoomDashboardScreen(
                    club: widget.club,
                    user: widget.user,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<ClubRoom>>(
        stream: _service.roomsStream(widget.club.id),
        builder: (context, snapshot) {
          final rooms = snapshot.data ?? const <ClubRoom>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rooms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 54,
                      color: cs.onSurface.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isManager
                          ? 'Create the first club room'
                          : 'No club rooms yet',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isManager) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _createRoom,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New Room'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                child: ListTile(
                  onTap: () => _openRoom(room),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (room.imageBase64 ?? '').isEmpty
                        ? Icon(Icons.forum_rounded, color: cs.primary)
                        : Base64Image(data: room.imageBase64!),
                  ),
                  title: Text(
                    room.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    room.isDefault ? 'Default room' : 'Club room',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: _isManager
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Invite event group',
                              icon: const Icon(Icons.groups_2_rounded),
                              onPressed: () => _inviteEventGroup(room),
                            ),
                            IconButton(
                              tooltip: 'Invite by email',
                              icon: const Icon(Icons.person_add_alt_rounded),
                              onPressed: () => _invite(room),
                            ),
                          ],
                        )
                      : const Icon(Icons.chevron_right_rounded),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isManager
          ? FloatingActionButton.extended(
              onPressed: _createRoom,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Room'),
            )
          : null,
    );
  }
}
