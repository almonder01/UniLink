import 'package:flutter/material.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../widgets/event_card.dart';
import '../student/event_detail_screen.dart';
import 'create_event_screen.dart';
import 'event_dashboard_screen.dart';
import 'manager_action_banner.dart';
import 'menu_tile.dart';
import 'popup_menu_position.dart';
import 'three_dot_button.dart';

class EventsTab extends StatefulWidget {
  final ClubModel club;
  final ValueChanged<int>? onCountChanged;

  const EventsTab({super.key, required this.club, this.onCountChanged});

  @override
  State<EventsTab> createState() => EventsTabState();
}

class EventsTabState extends State<EventsTab> {
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
    final events = await EventService().getEventsByClub(widget.club.id);
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
      await EventService().deleteEvent(event.id);
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

  void _showEventMenu(BuildContext anchorContext, EventModel event) {
    showMenu<String>(
      context: anchorContext,
      position: popupMenuPositionForAnchor(anchorContext),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: const [
        PopupMenuItem(
            value: 'edit',
            child: PopupMenuTile(Icons.edit_outlined, 'Edit')),
        PopupMenuItem(
            value: 'delete',
            child: PopupMenuTile(Icons.delete_outline_rounded, 'Delete',
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
      return Column(
        children: [
          _EventsHeader(club: widget.club),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined,
                      size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('No events yet. Tap + to create one.',
                      style:
                          TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _EventsHeader(club: widget.club),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _events.length,
            itemBuilder: (ctx, i) {
              final event = _events[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
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
                        onTap: (buttonContext) =>
                            _showEventMenu(buttonContext, event),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EventsHeader extends StatelessWidget {
  final ClubModel club;

  const _EventsHeader({required this.club});

  @override
  Widget build(BuildContext context) {
    return ManagerActionBanner(
      icon: Icons.insights_rounded,
      title: 'Events',
      subtitle: 'Create, edit, delete, and monitor event activity',
      tooltip: 'Event dashboard',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDashboardScreen(club: club),
        ),
      ),
    );
  }
}
