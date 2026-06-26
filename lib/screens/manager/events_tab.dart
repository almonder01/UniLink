import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../widgets/event_card.dart';
import '../student/event_detail_screen.dart';
import 'create_event_screen.dart';
import 'menu_tile.dart';
import 'three_dot_button.dart';

class EventsTab extends StatefulWidget {
  final ClubModel club;
  final ValueChanged<int>? onCountChanged;

  const EventsTab({super.key, required this.club, this.onCountChanged});

  @override
  State<EventsTab> createState() => EventsTabState();
}

class EventsTabState extends State<EventsTab> {
  final _db = FirebaseFirestore.instance;
  List<EventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _reportCount() {
    widget.onCountChanged?.call(_events.length);
  }

  Future<void> _loadEvents() async {
    final snap = await _db
        .collection('events')
        .where('clubId', isEqualTo: widget.club.id)
        .get();
    final events = snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    if (mounted) setState(() => _events = events);
    _reportCount();
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('This event will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _db.collection('events').doc(event.id).delete();
      if (!mounted) return;
      setState(() => _events.remove(event));
      _reportCount();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Event deleted'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting event: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _editEvent(EventModel event) async {
    final result = await Navigator.push<EventModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(
          club: widget.club,
          existingEvent: event,
        ),
      ),
    );
    if (result != null) _loadEvents();
  }

  void createNewEvent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(club: widget.club),
      ),
    );
    _loadEvents();
  }

  RelativeRect _menuPosition(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RelativeRect.fromLTRB(size.width - 160, 100, 16, 0);
  }

  void _showEventMenu(BuildContext context, EventModel event) {
    showMenu<String>(
      context: context,
      position: _menuPosition(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem(
            value: 'edit', child: MenuTile(Icons.edit_outlined, 'Edit')),
        PopupMenuItem(
            value: 'delete',
            child: MenuTile(Icons.delete_outline_rounded, 'Delete',
                color: Colors.red)),
      ],
    ).then((val) {
      if (val == 'edit') _editEvent(event);
      if (val == 'delete') _deleteEvent(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined,
                size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No events yet. Tap + to create one.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (ctx, i) {
        final event = _events[i];
        return Stack(
          children: [
            EventCard(
              event: event,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: ThreeDotButton(
                onTap: () => _showEventMenu(ctx, event),
              ),
            ),
          ],
        );
      },
    );
  }
}
