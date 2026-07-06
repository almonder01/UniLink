part of '../club_room_settings_screen.dart';

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
