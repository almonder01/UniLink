import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/club.dart';
import '../../models/event.dart';
import '../../models/event_analytics.dart';
import '../../models/event_registration.dart';
import '../../services/event_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/confirm_action_dialog.dart';

part 'event_dashboard/event_stage_filter.dart';
part 'event_dashboard/event_filter.dart';
part 'event_dashboard/stats_grid.dart';
part 'event_dashboard/stat_card.dart';
part 'event_dashboard/event_analytics_card.dart';
part 'event_dashboard/event_stage_chip.dart';
part 'event_dashboard/metric_chip.dart';
part 'event_dashboard/participants_sheet.dart';
part 'event_dashboard/participants_sheet_state.dart';
part 'event_dashboard/participant_summary_card.dart';
part 'event_dashboard/pending_registration_tile.dart';
part 'event_dashboard/mini_count_chip.dart';
part 'event_dashboard/sheet_section_label.dart';
part 'event_dashboard/registration_status_dialog.dart';
part 'event_dashboard/registration_status_dialog_state.dart';
part 'event_dashboard/registration_manager_card.dart';
part 'event_dashboard/status_chip.dart';
part 'event_dashboard/event_settings_sheet.dart';
part 'event_dashboard/event_settings_sheet_state.dart';
part 'event_dashboard/event_payments_panel.dart';
part 'event_dashboard/event_invites_panel.dart';
part 'event_dashboard/event_documents_panel.dart';
part 'event_dashboard/mini_dashboard_row.dart';
part 'event_dashboard/mini_stat.dart';
part 'event_dashboard/empty_dashboard.dart';

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
