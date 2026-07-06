import 'event.dart';

class EventAnalytics {
  final List<EventModel> events;
  final int totalRegistrations;
  final int totalAttendance;
  final Map<String, int> registrationsByEvent;
  final Map<String, int> attendanceByEvent;

  const EventAnalytics({
    required this.events,
    required this.totalRegistrations,
    required this.totalAttendance,
    required this.registrationsByEvent,
    required this.attendanceByEvent,
  });

  int get totalEvents => events.length;

  double get attendanceRate {
    if (totalRegistrations == 0) return 0;
    return totalAttendance / totalRegistrations;
  }

  int registrationsFor(String eventId) => registrationsByEvent[eventId] ?? 0;

  int attendanceFor(String eventId) => attendanceByEvent[eventId] ?? 0;
}
