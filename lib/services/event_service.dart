import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../models/event_analytics.dart';
import '../models/event_registration.dart';
import '../models/user.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  CollectionReference<Map<String, dynamic>> get _registrations =>
      _db.collection('event_registrations');

  Future<void> saveEvent(EventModel event) =>
      _events.doc(event.id).set(event.toMap());

  Future<void> updateEvent(EventModel event) =>
      _events.doc(event.id).update(event.toMap());

  Future<void> deleteEvent(String id) => _events.doc(id).delete();

  Future<List<EventModel>> getAllEvents({String? userId}) async {
    final snap = await _events.get();
    final events = snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return _withRegistrationState(events, userId);
  }

  Future<List<EventModel>> getEventsByClub(String clubId,
      {String? userId}) async {
    final snap = await _events.where('clubId', isEqualTo: clubId).get();
    final events = snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return _withRegistrationState(events, userId);
  }

  Future<List<EventModel>> _withRegistrationState(
    List<EventModel> events,
    String? userId,
  ) async {
    if (userId == null || userId.isEmpty || events.isEmpty) return events;

    final snap =
        await _registrations.where('userId', isEqualTo: userId).get();
    final registeredEventIds = snap.docs
        .map((d) => d.data()['eventId'] as String?)
        .whereType<String>()
        .toSet();

    return events
        .map((event) =>
            event.copyWith(isRegistered: registeredEventIds.contains(event.id)))
        .toList();
  }

  Future<bool> isRegistered(String eventId, String userId) async {
    if (userId.isEmpty) return false;
    final doc = await _registrations.doc(_registrationId(eventId, userId)).get();
    return doc.exists;
  }

  Future<void> registerForEvent({
    required EventModel event,
    required UserModel user,
  }) async {
    final registrationId = _registrationId(event.id, user.id);
    final registration = EventRegistration(
      id: registrationId,
      eventId: event.id,
      eventTitle: event.title,
      clubId: event.clubId,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      studentId: user.studentId,
      registeredAt: DateTime.now(),
    );

    await _db.runTransaction((tx) async {
      final regRef = _registrations.doc(registrationId);
      final regDoc = await tx.get(regRef);
      if (regDoc.exists) return;
      tx.set(regRef, registration.toMap());
      tx.update(_events.doc(event.id), {
        'registeredCount': FieldValue.increment(1),
      });
    });
  }

  Future<void> setAttendance({
    required EventRegistration registration,
    required bool attended,
  }) async {
    if (registration.attended == attended) return;

    await _db.runTransaction((tx) async {
      tx.update(_registrations.doc(registration.id), {'attended': attended});
      tx.update(_events.doc(registration.eventId), {
        'attendedCount': FieldValue.increment(attended ? 1 : -1),
      });
    });
  }

  Future<List<EventRegistration>> getRegistrationsForEvent(
      String eventId) async {
    final snap =
        await _registrations.where('eventId', isEqualTo: eventId).get();
    final registrations =
        snap.docs.map((d) => EventRegistration.fromMap(d.data())).toList();
    registrations.sort((a, b) => a.userName.compareTo(b.userName));
    return registrations;
  }

  Future<EventAnalytics> getAnalyticsForClub(String clubId) async {
    final events = await getEventsByClub(clubId);
    final registrationsSnap =
        await _registrations.where('clubId', isEqualTo: clubId).get();

    final registrationsByEvent = <String, int>{};
    final attendanceByEvent = <String, int>{};
    for (final doc in registrationsSnap.docs) {
      final registration = EventRegistration.fromMap(doc.data());
      registrationsByEvent.update(
        registration.eventId,
        (currentCount) => currentCount + 1,
        ifAbsent: () => 1,
      );
      if (registration.attended) {
        attendanceByEvent.update(
          registration.eventId,
          (currentCount) => currentCount + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return EventAnalytics(
      events: events,
      totalRegistrations: registrationsSnap.size,
      totalAttendance: registrationsSnap.docs
          .where((doc) => doc.data()['attended'] == true)
          .length,
      registrationsByEvent: registrationsByEvent,
      attendanceByEvent: attendanceByEvent,
    );
  }

  String _registrationId(String eventId, String userId) => '${eventId}_$userId';
}
