part of '../club_room_dashboard_screen.dart';

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
        content: Text(
          'Delete ${widget.room.name}? Messages will no longer be shown.',
        ),
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
