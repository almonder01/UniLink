import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/club.dart';
import '../../models/event.dart';
import '../../models/event_analytics.dart';
import '../../models/event_registration.dart';
import '../../services/event_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/base64_image.dart';

class EventDashboardTab extends StatefulWidget {
  final ClubModel club;

  const EventDashboardTab({super.key, required this.club});

  @override
  State<EventDashboardTab> createState() => _EventDashboardTabState();
}

class _EventDashboardTabState extends State<EventDashboardTab> {
  late Future<EventAnalytics> _analyticsFuture;
  String _selectedEventId = 'all';
  String _selectedStage = 'all';

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
      builder: (_) => _ParticipantsSheet(
        club: widget.club,
        event: event,
        onChanged: _refresh,
      ),
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
        final stagedEvents = analytics.events
            .where((event) => _eventMatchesStage(event, _selectedStage))
            .toList();
        EventModel? selectedEvent;
        if (_selectedEventId != 'all') {
          for (final event in stagedEvents) {
            if (event.id == _selectedEventId) {
              selectedEvent = event;
              break;
            }
          }
        }
        final stagedAnalytics = EventAnalytics(
          events: stagedEvents,
          totalRegistrations: stagedEvents.fold<int>(
            0,
            (total, event) => total + analytics.registrationsFor(event.id),
          ),
          totalAttendance: stagedEvents.fold<int>(
            0,
            (total, event) => total + analytics.attendanceFor(event.id),
          ),
          registrationsByEvent: analytics.registrationsByEvent,
          attendanceByEvent: analytics.attendanceByEvent,
        );
        final visibleAnalytics = selectedEvent == null
            ? stagedAnalytics
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
              _EventStageFilter(
                selectedStage: _selectedStage,
                onChanged: (stage) {
                  setState(() {
                    _selectedStage = stage;
                    _selectedEventId = 'all';
                  });
                },
              ),
              const SizedBox(height: 12),
              _EventFilter(
                events: stagedEvents,
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

  bool _eventMatchesStage(EventModel event, String stage) {
    if (stage == 'all') return true;
    final now = DateTime.now();
    final estimatedEnd = event.eventDate.add(const Duration(hours: 3));
    return switch (stage) {
      'planned' => event.eventDate.isAfter(now),
      'ongoing' =>
        !event.eventDate.isAfter(now) && estimatedEnd.isAfter(now),
      'ended' => !estimatedEnd.isAfter(now),
      _ => true,
    };
  }
}

class _EventStageFilter extends StatelessWidget {
  final String selectedStage;
  final ValueChanged<String> onChanged;

  const _EventStageFilter({
    required this.selectedStage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const filters = [
      MapEntry('all', 'All'),
      MapEntry('planned', 'Planning'),
      MapEntry('ongoing', 'Ongoing'),
      MapEntry('ended', 'Ended'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVENT STATUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in filters)
              FilterChip(
                label: Text(filter.value),
                selected: selectedStage == filter.key,
                onSelected: (_) => onChanged(filter.key),
                selectedColor: cs.primary.withValues(alpha: 0.15),
                checkmarkColor: cs.primary,
              ),
          ],
        ),
      ],
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
              const SizedBox(height: 10),
              _EventStageChip(event: event),
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

class _EventStageChip extends StatelessWidget {
  final EventModel event;

  const _EventStageChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final estimatedEnd = event.eventDate.add(const Duration(hours: 3));
    final (label, icon, color) = event.eventDate.isAfter(now)
        ? ('Planning', Icons.schedule_rounded, const Color(0xFF6366F1))
        : estimatedEnd.isAfter(now)
            ? ('Ongoing', Icons.play_circle_rounded, const Color(0xFF22C55E))
            : ('Ended', Icons.flag_rounded, const Color(0xFF64748B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
  final ClubModel club;
  final EventModel event;
  final Future<void> Function() onChanged;

  const _ParticipantsSheet({
    required this.club,
    required this.event,
    required this.onChanged,
  });

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

  Future<void> _changeStatus(
    EventRegistration registration,
    String status,
  ) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => _RegistrationStatusDialog(
        title: _statusDialogTitle(status),
        subtitle: '${registration.userName} - ${registration.eventTitle}',
        initialMessage: _defaultStatusMessage(registration, status),
      ),
    );
    if (!mounted) return;
    if (message == null) return;

    await EventService().updateRegistrationStatus(
      registration: registration,
      status: status,
      message: message,
    );
    await widget.onChanged();
    setState(() {
      _registrationsFuture =
          EventService().getRegistrationsForEvent(widget.event.id);
    });
  }

  Future<void> _approvePending(List<EventRegistration> registrations) async {
    if (registrations.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve pending requests?'),
        content: Text('Approve ${registrations.length} registration request(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    for (final registration in registrations) {
      await EventService().updateRegistrationStatus(
        registration: registration,
        status: 'approved',
        message: 'Your registration for ${registration.eventTitle} has been approved.',
      );
    }
    await widget.onChanged();
    if (!mounted) return;
    setState(() {
      _registrationsFuture =
          EventService().getRegistrationsForEvent(widget.event.id);
    });
  }

  String _statusDialogTitle(String status) {
    return switch (status) {
      'approved' => 'Approve registration?',
      'rejected' => 'Reject registration?',
      'cancelled' => 'Cancel registration?',
      _ => 'Update registration?',
    };
  }

  String _defaultStatusMessage(
    EventRegistration registration,
    String status,
  ) {
    return switch (status) {
      'approved' =>
        'Your registration for ${registration.eventTitle} has been approved.',
      'rejected' =>
        'Your registration for ${registration.eventTitle} has been rejected.',
      'cancelled' =>
        'Your registration for ${registration.eventTitle} has been cancelled.',
      _ => 'Your registration for ${registration.eventTitle} was updated.',
    };
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EventSettingsSheet(
        club: widget.club,
        event: widget.event,
      ),
    );
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
                    tooltip: 'Event settings',
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded),
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
                  final pending = registrations
                      .where((registration) => registration.isPending)
                      .toList();
                  final approved = registrations
                      .where((registration) => registration.isApproved)
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                    children: [
                      _ParticipantSummaryCard(
                        approvedCount: approved.length,
                        pendingCount: pending.length,
                        onApprovePending: pending.isEmpty
                            ? null
                            : () => _approvePending(pending),
                      ),
                      if (pending.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const _SheetSectionLabel('Pending requests'),
                        const SizedBox(height: 8),
                        ...pending.map(
                          (registration) => _PendingRegistrationTile(
                            registration: registration,
                            onApprove: () =>
                                _changeStatus(registration, 'approved'),
                            onReject: () =>
                                _changeStatus(registration, 'rejected'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const _SheetSectionLabel('Attendance'),
                      const SizedBox(height: 8),
                      if (approved.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              'No approved participants yet.',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        )
                      else
                        ...approved.map(
                          (registration) => _RegistrationManagerCard(
                            registration: registration,
                            onAttendanceChanged: (value) =>
                                _setAttendance(registration, value),
                            onApprove: null,
                            onReject: null,
                            onCancel: () =>
                                _changeStatus(registration, 'cancelled'),
                          ),
                        ),
                    ],
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

class _ParticipantSummaryCard extends StatelessWidget {
  final int approvedCount;
  final int pendingCount;
  final VoidCallback? onApprovePending;

  const _ParticipantSummaryCard({
    required this.approvedCount,
    required this.pendingCount,
    required this.onApprovePending,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniCountChip(
                    icon: Icons.fact_check_rounded,
                    label: '$approvedCount approved',
                    color: const Color(0xFF22C55E),
                  ),
                  _MiniCountChip(
                    icon: Icons.pending_actions_rounded,
                    label: '$pendingCount pending',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onApprovePending,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Approve all'),
              style: FilledButton.styleFrom(
                foregroundColor: cs.primary,
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRegistrationTile extends StatelessWidget {
  final EventRegistration registration;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRegistrationTile({
    required this.registration,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pending_actions_rounded,
                  color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    registration.userName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    registration.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Approve',
              onPressed: onApprove,
              icon: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E)),
            ),
            IconButton(
              tooltip: 'Reject',
              onPressed: onReject,
              icon:
                  const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniCountChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String label;

  const _SheetSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _RegistrationStatusDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String initialMessage;

  const _RegistrationStatusDialog({
    required this.title,
    required this.subtitle,
    required this.initialMessage,
  });

  @override
  State<_RegistrationStatusDialog> createState() =>
      _RegistrationStatusDialogState();
}

class _RegistrationStatusDialogState extends State<_RegistrationStatusDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialMessage);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.subtitle),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notification message',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _RegistrationManagerCard extends StatelessWidget {
  final EventRegistration registration;
  final ValueChanged<bool>? onAttendanceChanged;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const _RegistrationManagerCard({
    required this.registration,
    required this.onAttendanceChanged,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final receipt = registration.paymentReceiptBase64;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.person_rounded, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registration.userName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        [
                          registration.userEmail,
                          if (registration.studentId.isNotEmpty)
                            registration.studentId,
                        ].join(' - '),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: registration.status),
              ],
            ),
            if ((receipt ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => showBase64ImagePreview(context, data: receipt!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 16, color: Color(0xFF14B8A6)),
                      SizedBox(width: 6),
                      Text(
                        'View transfer receipt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14B8A6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if ((registration.requirementTextResponse ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirement answer',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registration.requirementTextResponse!,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
            if ((registration.requirementFileBase64 ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => showBase64ImagePreview(
                  context,
                  data: registration.requirementFileBase64!,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_file_rounded,
                          size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        'View required file',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Attended'),
                  selected: registration.attended,
                  onSelected: onAttendanceChanged,
                  avatar: const Icon(Icons.fact_check_rounded, size: 16),
                ),
                FilledButton.tonalIcon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('Pending', const Color(0xFFF59E0B)),
      'approved' => ('Approved', const Color(0xFF22C55E)),
      'rejected' => ('Rejected', const Color(0xFFEF4444)),
      'cancelled' => ('Cancelled', const Color(0xFF64748B)),
      _ => ('Updated', Theme.of(context).colorScheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EventSettingsSheet extends StatefulWidget {
  final ClubModel club;
  final EventModel event;

  const _EventSettingsSheet({
    required this.club,
    required this.event,
  });

  @override
  State<_EventSettingsSheet> createState() => _EventSettingsSheetState();
}

class _EventSettingsSheetState extends State<_EventSettingsSheet> {
  final _emailCtrl = TextEditingController();
  bool _sendingFollowers = false;
  bool _sendingEmail = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _inviteFollowers() async {
    setState(() => _sendingFollowers = true);
    try {
      await NotificationService().sendEventInviteToFollowers(
        club: widget.club,
        eventId: widget.event.id,
        eventTitle: widget.event.title,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation sent to followers.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingFollowers = false);
    }
  }

  Future<void> _inviteEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _sendingEmail = true);
    try {
      await NotificationService().sendEventInviteByEmail(
        club: widget.club,
        eventId: widget.event.id,
        eventTitle: widget.event.title,
        email: email,
      );
      _emailCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Event Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              widget.event.title,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.payments_rounded), text: 'Payments'),
                      Tab(icon: Icon(Icons.send_rounded), text: 'Invites'),
                      Tab(icon: Icon(Icons.folder_copy_rounded), text: 'Docs'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _EventPaymentsPanel(event: widget.event),
                        _EventInvitesPanel(
                          emailCtrl: _emailCtrl,
                          sendingFollowers: _sendingFollowers,
                          sendingEmail: _sendingEmail,
                          onInviteFollowers: _inviteFollowers,
                          onInviteEmail: _inviteEmail,
                        ),
                        _EventDocumentsPanel(event: widget.event),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventPaymentsPanel extends StatelessWidget {
  final EventModel event;

  const _EventPaymentsPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<EventRegistration>>(
      future: EventService().getRegistrationsForEvent(event.id),
      builder: (context, snapshot) {
        final registrations = snapshot.data ?? const <EventRegistration>[];
        final receipts = registrations
            .where((registration) =>
                (registration.paymentReceiptBase64 ?? '').isNotEmpty)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.payments_rounded),
              title: const Text('Event fee'),
              subtitle: Text(event.feeLabel),
            ),
            _MiniDashboardRow(
              firstLabel: 'Receipts',
              firstValue: '${receipts.length}',
              secondLabel: 'Expected',
              secondValue: event.requiresPayment
                  ? '${registrations.where((r) => r.isActive).length}'
                  : '0',
            ),
            const SizedBox(height: 8),
            if (!event.requiresPayment)
              Text(
                'This event is free. No payment receipts are required.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              )
            else if (receipts.isEmpty)
              Text(
                'No receipts uploaded yet.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              )
            else
              ...receipts.take(5).map(
                    (registration) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_rounded),
                      title: Text(registration.userName),
                      subtitle: Text(registration.userEmail),
                      trailing: TextButton(
                        onPressed: () => showBase64ImagePreview(
                          context,
                          data: registration.paymentReceiptBase64!,
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _EventInvitesPanel extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool sendingFollowers;
  final bool sendingEmail;
  final VoidCallback onInviteFollowers;
  final VoidCallback onInviteEmail;

  const _EventInvitesPanel({
    required this.emailCtrl,
    required this.sendingFollowers,
    required this.sendingEmail,
    required this.onInviteFollowers,
    required this.onInviteEmail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
      children: [
        FilledButton.icon(
          onPressed: sendingFollowers ? null : onInviteFollowers,
          icon: sendingFollowers
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications_active_rounded),
          label: const Text('Invite all followers'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Invite by email',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            suffixIcon: IconButton(
              onPressed: sendingEmail ? null : onInviteEmail,
              icon: sendingEmail
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
          onSubmitted: (_) => onInviteEmail(),
        ),
      ],
    );
  }
}

class _EventDocumentsPanel extends StatelessWidget {
  final EventModel event;

  const _EventDocumentsPanel({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<EventRegistration>>(
      future: EventService().getRegistrationsForEvent(event.id),
      builder: (context, snapshot) {
        final registrations = snapshot.data ?? const <EventRegistration>[];
        final files = registrations
            .where((registration) =>
                (registration.requirementFileBase64 ?? '').isNotEmpty)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 12),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link_rounded),
              title: const Text('External form'),
              subtitle: Text(event.externalFormUrl?.isNotEmpty == true
                  ? event.externalFormUrl!
                  : 'No external form link'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rule_folder_rounded),
              title: const Text('Additional requirement'),
              subtitle: Text(
                event.registrationRequirementPrompt?.isNotEmpty == true
                    ? event.registrationRequirementPrompt!
                    : 'No additional requirement prompt',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${files.length} uploaded requirement file(s)',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...files.take(5).map(
                  (registration) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file_rounded),
                    title: Text(registration.userName),
                    subtitle: Text(registration.userEmail),
                    trailing: TextButton(
                      onPressed: () => showBase64ImagePreview(
                        context,
                        data: registration.requirementFileBase64!,
                      ),
                      child: const Text('View'),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _MiniDashboardRow extends StatelessWidget {
  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondValue;

  const _MiniDashboardRow({
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(label: firstLabel, value: firstValue)),
        const SizedBox(width: 8),
        Expanded(child: _MiniStat(label: secondLabel, value: secondValue)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
