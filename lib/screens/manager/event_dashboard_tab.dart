import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/club.dart';
import '../../models/event.dart';
import '../../models/event_analytics.dart';
import '../../models/event_registration.dart';
import '../../services/event_service.dart';

class EventDashboardTab extends StatefulWidget {
  final ClubModel club;

  const EventDashboardTab({super.key, required this.club});

  @override
  State<EventDashboardTab> createState() => _EventDashboardTabState();
}

class _EventDashboardTabState extends State<EventDashboardTab> {
  late Future<EventAnalytics> _analyticsFuture;
  String _selectedEventId = 'all';

  @override
  void initState() {
    super.initState();
    _analyticsFuture = EventService().getAnalyticsForClub(widget.club.id);
  }

  Future<void> _refresh() async {
    setState(() {
      _analyticsFuture = EventService().getAnalyticsForClub(widget.club.id);
    });
    await _analyticsFuture;
  }

  Future<void> _showParticipants(EventModel event) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ParticipantsSheet(event: event, onChanged: _refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventAnalytics>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
        }

        final analytics = snapshot.data!;
        EventModel? selectedEvent;
        if (_selectedEventId != 'all') {
          for (final event in analytics.events) {
            if (event.id == _selectedEventId) {
              selectedEvent = event;
              break;
            }
          }
        }
        final visibleAnalytics = selectedEvent == null
            ? analytics
            : EventAnalytics(
                events: [selectedEvent],
                totalRegistrations:
                    analytics.registrationsFor(selectedEvent.id),
                totalAttendance: analytics.attendanceFor(selectedEvent.id),
                registrationsByEvent: analytics.registrationsByEvent,
                attendanceByEvent: analytics.attendanceByEvent,
              );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EventFilter(
                events: analytics.events,
                selectedEventId: _selectedEventId,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedEventId = value);
                },
              ),
              const SizedBox(height: 12),
              _StatsGrid(analytics: visibleAnalytics),
              const SizedBox(height: 18),
              const Text(
                'Event Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (visibleAnalytics.events.isEmpty)
                const _EmptyDashboard()
              else
                ...visibleAnalytics.events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventAnalyticsCard(
                      event: event,
                      registrations:
                          visibleAnalytics.registrationsFor(event.id),
                      attendance: visibleAnalytics.attendanceFor(event.id),
                      onTap: () => _showParticipants(event),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EventFilter extends StatelessWidget {
  final List<EventModel> events;
  final String selectedEventId;
  final ValueChanged<String?> onChanged;

  const _EventFilter({
    required this.events,
    required this.selectedEventId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filters = [
      const MapEntry('all', 'All events'),
      ...events.map((event) => MapEntry(event.id, event.title)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DASHBOARD FILTER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final filter = filters[index];
              final selected = selectedEventId == filter.key;
              return FilterChip(
                label: Text(
                  filter.value,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selected,
                onSelected: (_) => onChanged(filter.key),
                selectedColor: cs.primary.withValues(alpha: 0.15),
                checkmarkColor: cs.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.65),
                ),
                side: BorderSide(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final EventAnalytics analytics;

  const _StatsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = [
          _StatCard(
            icon: Icons.event_available_rounded,
            label: 'Events',
            value: '${analytics.totalEvents}',
            color: const Color(0xFFF97316),
          ),
          _StatCard(
            icon: Icons.how_to_reg_rounded,
            label: 'Registrations',
            value: '${analytics.totalRegistrations}',
            color: const Color(0xFF14B8A6),
          ),
          _StatCard(
            icon: Icons.fact_check_rounded,
            label: 'Attendance',
            value: '${analytics.totalAttendance}',
            color: const Color(0xFF22C55E),
          ),
          _StatCard(
            icon: Icons.insights_rounded,
            label: 'Attendance Rate',
            value: '${(analytics.attendanceRate * 100).round()}%',
            color: const Color(0xFF6366F1),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventAnalyticsCard extends StatelessWidget {
  final EventModel event;
  final int registrations;
  final int attendance;
  final VoidCallback onTap;

  const _EventAnalyticsCard({
    required this.event,
    required this.registrations,
    required this.attendance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rate = registrations == 0 ? 0.0 : attendance / registrations;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('MMM d, y - h:mm a')
                              .format(event.eventDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: rate.clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MetricChip(
                    icon: Icons.how_to_reg_rounded,
                    label: '$registrations registered',
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    icon: Icons.fact_check_rounded,
                    label: '$attendance attended',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: cs.onSurface.withValues(alpha: 0.55)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSheet extends StatefulWidget {
  final EventModel event;
  final Future<void> Function() onChanged;

  const _ParticipantsSheet({required this.event, required this.onChanged});

  @override
  State<_ParticipantsSheet> createState() => _ParticipantsSheetState();
}

class _ParticipantsSheetState extends State<_ParticipantsSheet> {
  late Future<List<EventRegistration>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    _registrationsFuture =
        EventService().getRegistrationsForEvent(widget.event.id);
  }

  Future<void> _setAttendance(
    EventRegistration registration,
    bool attended,
  ) async {
    await EventService().setAttendance(
      registration: registration,
      attended: attended,
    );
    await widget.onChanged();
    setState(() {
      _registrationsFuture =
          EventService().getRegistrationsForEvent(widget.event.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Participants and attendance',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<EventRegistration>>(
                future: _registrationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final registrations =
                      snapshot.data ?? const <EventRegistration>[];
                  if (registrations.isEmpty) {
                    return const Center(child: Text('No registrations yet.'));
                  }
                  return ListView.builder(
                    itemCount: registrations.length,
                    itemBuilder: (_, index) {
                      final registration = registrations[index];
                      return SwitchListTile(
                        value: registration.attended,
                        onChanged: (value) =>
                            _setAttendance(registration, value),
                        title: Text(
                          registration.userName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            registration.userEmail,
                            if (registration.studentId.isNotEmpty)
                              registration.studentId,
                          ].join(' - '),
                        ),
                        secondary: const Icon(Icons.person_rounded),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 54,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'Create an event to start seeing analytics.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
