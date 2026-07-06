import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club.dart';
import '../../models/club_room.dart';
import '../../models/user.dart';
import '../../services/club_room_service.dart';
import '../../widgets/base64_image.dart';

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

class _RoomDashboardTile extends StatelessWidget {
  final ClubRoom room;
  final bool canManage;
  final VoidCallback onTap;

  const _RoomDashboardTile({
    required this.room,
    required this.canManage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: canManage ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _RoomAvatar(room: room, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (room.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<List<String>>(
                      stream:
                          ClubRoomService().recentSpeakersStream(room.id),
                      builder: (context, snapshot) {
                        final speakers = snapshot.data ?? const <String>[];
                        final label = speakers.isEmpty
                            ? 'No messages yet'
                            : 'Recent: ${speakers.join(', ')}';
                        return Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (canManage)
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurface.withValues(alpha: 0.38),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomEditorSheet extends StatefulWidget {
  final ClubRoom room;

  const _RoomEditorSheet({required this.room});

  @override
  State<_RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState extends State<_RoomEditorSheet> {
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  String? _imageBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.room.name);
    _imageBase64 = widget.room.imageBase64;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 72,
    );
    if (file == null) return;
    final encoded = base64Encode(await file.readAsBytes());
    if (mounted) setState(() => _imageBase64 = encoded);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ClubRoomService().updateRoom(
        roomId: widget.room.id,
        name: _nameCtrl.text,
        imageBase64: _imageBase64,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeImage() async {
    await ClubRoomService().clearRoomImage(widget.room.id);
    if (mounted) setState(() => _imageBase64 = null);
  }

  Future<void> _deleteRoom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text('Delete ${widget.room.name}? Messages will no longer be shown.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ClubRoomService().deleteRoom(widget.room);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = (_imageBase64 ?? '').isNotEmpty;
    final previewRoom = ClubRoom(
      id: widget.room.id,
      clubId: widget.room.clubId,
      name: widget.room.name,
      createdBy: widget.room.createdBy,
      createdAt: widget.room.createdAt,
      guestIds: widget.room.guestIds,
      isDefault: widget.room.isDefault,
      imageBase64: _imageBase64,
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
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
            Row(
              children: [
                GestureDetector(
                  onTap: hasImage
                      ? () => showBase64ImagePreview(
                            context,
                            data: _imageBase64!,
                          )
                      : null,
                  child: _RoomAvatar(
                    room: previewRoom,
                    size: 64,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Room Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Room name',
                prefixIcon: Icon(Icons.forum_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Change image'),
                ),
                if (hasImage)
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.hide_image_outlined),
                    label: const Text('Remove image'),
                  ),
                if (!widget.room.isDefault)
                  TextButton.icon(
                    onPressed: _deleteRoom,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomAvatar extends StatelessWidget {
  final ClubRoom room;
  final double size;

  const _RoomAvatar({required this.room, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = room.imageBase64;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: cs.primary.withValues(alpha: 0.12),
        child: image == null || image.isEmpty
            ? Icon(Icons.forum_rounded, color: cs.primary, size: size * 0.42)
            : Base64Image(data: image),
      ),
    );
  }
}
