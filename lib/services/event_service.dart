import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../models/event_analytics.dart';
import '../models/event_registration.dart';
import '../models/user.dart';
import 'notification_service.dart';

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
      _events.doc(event.id).set(event.toMap());

  Future<void> deleteEvent(String id) => _events.doc(id).delete();

  Future<EventModel?> getEventById(String id, {String? userId}) async {
    final doc = await _events.doc(id).get();
    if (!doc.exists) return null;
    final event = EventModel.fromMap(doc.data()!);
    final events = await _withRegistrationState([event], userId);
    return events.isEmpty ? event : events.first;
  }

  Future<List<EventModel>> getAllEvents({String? userId}) async {
    final snap = await _events.get();
    final events = snap.docs.map((d) => EventModel.fromMap(d.data())).toList();
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return _withRegistrationState(events, userId);
  }

  Future<List<EventModel>> getUpcomingEvents({
    String? userId,
    int limit = 60,
  }) async {
    final snap = await _events
        .where('eventDate', isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
        .orderBy('eventDate')
        .limit(limit)
        .get();
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
    final registrationStatusByEvent = <String, String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final eventId = data['eventId'] as String?;
      final status = data['status'] as String? ?? 'approved';
      if (eventId == null || !_isCountedStatus(status)) continue;
      registrationStatusByEvent[eventId] = status;
    }

    return events.map((event) {
      final status = registrationStatusByEvent[event.id];
      return event.copyWith(
        isRegistered: status != null,
        registrationStatus: status,
      );
    }).toList();
  }

  Future<bool> isRegistered(String eventId, String userId) async {
    if (userId.isEmpty) return false;
    final doc = await _registrations.doc(_registrationId(eventId, userId)).get();
    if (!doc.exists) return false;
    final status = doc.data()?['status'] as String? ?? 'approved';
    return _isCountedStatus(status);
  }

  Future<void> registerForEvent({
    required EventModel event,
    required UserModel user,
    String? paymentReceiptBase64,
    String? requirementTextResponse,
    String? requirementFileBase64,
  }) async {
    final registrationId = _registrationId(event.id, user.id);
    final status =
        event.requiresPayment || event.hasRegistrationRequirement
            ? 'pending'
            : 'approved';
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
      status: status,
      paymentReceiptBase64: paymentReceiptBase64,
      paymentAmount: event.feeAmount,
      paymentCurrency: event.feeCurrency,
      requirementTextResponse: requirementTextResponse,
      requirementFileBase64: requirementFileBase64,
    );

    await _db.runTransaction((tx) async {
      final eventRef = _events.doc(event.id);
      final eventDoc = await tx.get(eventRef);
      if (!eventDoc.exists) {
        throw Exception('Event not found.');
      }

      final regRef = _registrations.doc(registrationId);
      final regDoc = await tx.get(regRef);
      if (regDoc.exists) {
        final oldStatus = regDoc.data()?['status'] as String? ?? 'approved';
        if (_isCountedStatus(oldStatus)) return;
        _ensureCapacity(eventDoc.data()!);
        tx.update(regRef, {
          ...registration.toMap(),
          'attended': false,
        });
        tx.update(eventRef, {
          'registeredCount': FieldValue.increment(1),
        });
      } else {
        _ensureCapacity(eventDoc.data()!);
        tx.set(regRef, registration.toMap());
        tx.update(eventRef, {
          'registeredCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> setAttendance({
    required EventRegistration registration,
    required bool attended,
  }) async {
    if (registration.attended == attended) return;
    if (!registration.isApproved) return;

    await _db.runTransaction((tx) async {
      tx.update(_registrations.doc(registration.id), {'attended': attended});
      tx.update(_events.doc(registration.eventId), {
        'attendedCount': FieldValue.increment(attended ? 1 : -1),
      });
    });
  }

  Future<void> updateRegistrationStatus({
    required EventRegistration registration,
    required String status,
    String? message,
  }) async {
    if (registration.status == status) return;
    final oldCounted = _isCountedStatus(registration.status);
    final newCounted = _isCountedStatus(status);
    final shouldClearAttendance = status != 'approved' && registration.attended;

    await _db.runTransaction((tx) async {
      tx.update(_registrations.doc(registration.id), {
        'status': status,
        'statusUpdatedAt': DateTime.now().toIso8601String(),
        if (shouldClearAttendance) 'attended': false,
      });
      if (oldCounted != newCounted) {
        tx.update(_events.doc(registration.eventId), {
          'registeredCount': FieldValue.increment(newCounted ? 1 : -1),
        });
      }
      if (shouldClearAttendance) {
        tx.update(_events.doc(registration.eventId), {
          'attendedCount': FieldValue.increment(-1),
        });
      }
    });

    await NotificationService().sendEventRegistrationStatus(
      userId: registration.userId,
      eventTitle: registration.eventTitle,
      clubId: registration.clubId,
      eventId: registration.eventId,
      status: status,
      message: message,
    );
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

  Future<List<EventRegistration>> getRegistrationsForUser(String userId) async {
    if (userId.isEmpty) return [];
    final snap =
        await _registrations.where('userId', isEqualTo: userId).get();
    final registrations =
        snap.docs.map((d) => EventRegistration.fromMap(d.data())).toList();
    registrations.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
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
      if (!registration.isActive) continue;
      registrationsByEvent.update(
        registration.eventId,
        (currentCount) => currentCount + 1,
        ifAbsent: () => 1,
      );
      if (registration.attended && registration.isApproved) {
        attendanceByEvent.update(
          registration.eventId,
          (currentCount) => currentCount + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return EventAnalytics(
      events: events,
      totalRegistrations: registrationsByEvent.values.fold<int>(
        0,
        (total, amount) => total + amount,
      ),
      totalAttendance: registrationsSnap.docs
          .where((doc) {
            final registration = EventRegistration.fromMap(doc.data());
            return registration.attended && registration.isApproved;
          })
          .length,
      registrationsByEvent: registrationsByEvent,
      attendanceByEvent: attendanceByEvent,
    );
  }

  bool _isCountedStatus(String status) =>
      status != 'rejected' && status != 'cancelled';

  void _ensureCapacity(Map<String, dynamic> eventData) {
    final maxParticipants = (eventData['maxParticipants'] as num?)?.toInt();
    if (maxParticipants == null || maxParticipants <= 0) return;
    final registeredCount =
        (eventData['registeredCount'] as num?)?.toInt() ?? 0;
    if (registeredCount >= maxParticipants) {
      throw Exception('This event is full.');
    }
  }

  String _registrationId(String eventId, String userId) => '${eventId}_$userId';
}
