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

class _RoomNameDialog extends StatefulWidget {
  const _RoomNameDialog();

  @override
  State<_RoomNameDialog> createState() => _RoomNameDialogState();
}

class _RoomNameDialogState extends State<_RoomNameDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Room'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Room name',
          prefixIcon: Icon(Icons.forum_outlined),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _RoomInviteDialog extends StatefulWidget {
  final String roomName;

  const _RoomInviteDialog({required this.roomName});

  @override
  State<_RoomInviteDialog> createState() => _RoomInviteDialogState();
}

class _RoomInviteDialogState extends State<_RoomInviteDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Invite to ${widget.roomName}'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Student email',
          prefixIcon: Icon(Icons.mail_outline_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Send Invite'),
        ),
      ],
    );
  }
}

class _RoomEventInviteSheet extends StatefulWidget {
  final ClubModel club;
  final ClubRoom room;
  final UserModel sender;

  const _RoomEventInviteSheet({
    required this.club,
    required this.room,
    required this.sender,
  });

  @override
  State<_RoomEventInviteSheet> createState() => _RoomEventInviteSheetState();
}

class _RoomEventInviteSheetState extends State<_RoomEventInviteSheet> {
  late Future<List<EventModel>> _eventsFuture;
  EventModel? _selectedEvent;
  String _target = 'approved';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _eventsFuture = EventService().getEventsByClub(widget.club.id);
  }

  Future<void> _send() async {
    final event = _selectedEvent;
    if (event == null) return;
    setState(() => _sending = true);
    try {
      final registrations =
          await EventService().getRegistrationsForEvent(event.id);
      final targets = registrations.where((registration) {
        if (_target == 'approved') return registration.isApproved;
        return registration.isActive;
      }).toList();
      for (final registration in targets) {
        await NotificationService().sendRoomInvite(
          userId: registration.userId,
          senderName: widget.sender.name,
          club: widget.club,
          room: widget.room,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room invite sent to ${targets.length} student(s).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: FutureBuilder<List<EventModel>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            final events = snapshot.data ?? const <EventModel>[];
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
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invite event group',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text('No events available.')),
                  )
                else ...[
                  DropdownButtonFormField<EventModel>(
                    initialValue: _selectedEvent,
                    decoration: const InputDecoration(
                      labelText: 'Event',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                    items: [
                      for (final event in events)
                        DropdownMenuItem(
                          value: event,
                          child: Text(
                            event.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (event) => setState(() => _selectedEvent = event),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'approved',
                        label: Text('Approved'),
                        icon: Icon(Icons.verified_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 'registered',
                        label: Text('Registered'),
                        icon: Icon(Icons.how_to_reg_rounded, size: 16),
                      ),
                    ],
                    selected: {_target},
                    onSelectionChanged: (selection) =>
                        setState(() => _target = selection.first),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Send Invites'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
