import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club.dart';
import '../../models/club_room.dart';
import '../../models/user.dart';
import '../../services/club_room_service.dart';
import '../../widgets/base64_image.dart';

part 'club_room_dashboard/room_avatar.dart';
part 'club_room_dashboard/room_dashboard_tile.dart';
part 'club_room_dashboard/room_editor_sheet.dart';

class ClubRoomDashboardScreen extends StatelessWidget {
  final ClubModel club;
  final UserModel user;

  const ClubRoomDashboardScreen({
    super.key,
    required this.club,
    required this.user,
  });

  bool get _isManager => user.id == club.managerId;

  Future<void> _openRoomEditor(
    BuildContext context,
    ClubRoom room,
  ) async {
    if (!_isManager) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RoomEditorSheet(room: room),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Room Dashboard')),
      body: StreamBuilder<List<ClubRoom>>(
        stream: ClubRoomService().roomsStream(club.id),
        builder: (context, snapshot) {
          final rooms = snapshot.data ?? const <ClubRoom>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                'No rooms yet',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
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
              return _RoomDashboardTile(
                room: room,
                canManage: _isManager,
                onTap: () => _openRoomEditor(context, room),
              );
            },
          );
        },
      ),
    );
  }
}
