import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/club.dart';
import '../models/club_room.dart';
import '../models/user.dart';
import 'notification_service.dart';

class ClubRoomService {
  static final ClubRoomService _instance = ClubRoomService._internal();
  factory ClubRoomService() => _instance;
  ClubRoomService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('club_rooms');

  Stream<List<ClubRoom>> roomsStream(String clubId) => _rooms
      .where('club_id', isEqualTo: clubId)
      .snapshots()
      .map((snap) {
        final rooms = snap.docs.map(ClubRoom.fromFirestore).toList();
        rooms.sort((a, b) {
          if (a.isDefault) return -1;
          if (b.isDefault) return 1;
          return a.createdAt.compareTo(b.createdAt);
        });
        return rooms;
      });

  Future<List<ClubRoom>> roomsForClub(String clubId) async {
    final snap = await _rooms.where('club_id', isEqualTo: clubId).get();
    final rooms = snap.docs.map(ClubRoom.fromFirestore).toList();
    rooms.sort((a, b) {
      if (a.isDefault) return -1;
      if (b.isDefault) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return rooms;
  }

  Future<List<ClubRoom>> roomsForClubIds(List<String> clubIds) async {
    final rooms = <ClubRoom>[];
    for (final clubId in clubIds.toSet()) {
      rooms.addAll(await roomsForClub(clubId));
    }
    return rooms;
  }

  Future<ClubRoom?> getRoom(String roomId) async {
    final doc = await _rooms.doc(roomId).get();
    return doc.exists ? ClubRoom.fromFirestore(doc) : null;
  }

  Future<ClubRoom> ensureDefaultRoom({
    required ClubModel club,
    required String createdBy,
  }) async {
    final existing = await roomsForClub(club.id);
    if (existing.isNotEmpty) return existing.first;
    return createRoom(
      clubId: club.id,
      name: 'General',
      createdBy: createdBy,
      isDefault: true,
    );
  }

  Future<ClubRoom> createRoom({
    required String clubId,
    required String name,
    required String createdBy,
    bool isDefault = false,
  }) async {
    final ref = _rooms.doc();
    await ref.set({
      'club_id': clubId,
      'name': name.trim().isEmpty ? 'Room' : name.trim(),
      'created_by': createdBy,
      'created_at': FieldValue.serverTimestamp(),
      'guest_ids': <String>[],
      'is_default': isDefault,
    });
    final doc = await ref.get();
    return ClubRoom.fromFirestore(doc);
  }

  Future<void> updateRoom({
    required String roomId,
    String? name,
    String? imageBase64,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if (imageBase64 != null) {
      updates['image_base64'] = imageBase64;
    }
    if (updates.isEmpty) return;
    await _rooms.doc(roomId).update(updates);
  }

  Future<void> clearRoomImage(String roomId) async {
    await _rooms.doc(roomId).update({'image_base64': FieldValue.delete()});
  }

  Future<void> deleteRoom(ClubRoom room) async {
    if (room.isDefault) {
      throw Exception('The default room cannot be deleted.');
    }
    await _rooms.doc(room.id).delete();
  }

  Stream<List<ChatMessage>> messagesStream(String roomId) => _rooms
      .doc(roomId)
      .collection('messages')
      .orderBy('created_at')
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());

  Stream<List<String>> recentSpeakersStream(String roomId) => _rooms
      .doc(roomId)
      .collection('messages')
      .orderBy('created_at', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) {
        final names = <String>[];
        for (final doc in snap.docs) {
          final name = doc.data()['sender_name'] as String? ?? 'Student';
          if (!names.contains(name)) names.add(name);
          if (names.length == 4) break;
        }
        return names;
      });

  Future<void> sendMessage({
    required String roomId,
    required UserModel sender,
    String text = '',
    String? attachmentType,
    String? attachmentId,
    String? attachmentTitle,
    String? attachmentSubtitle,
    String? attachmentClubId,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && attachmentId == null) return;
    await _rooms.doc(roomId).collection('messages').add({
      'sender_id': sender.id,
      'sender_name': sender.name,
      'sender_photo_base64': sender.photoBase64,
      'sender_gender': sender.gender,
      'text': cleanText,
      'attachment_type': attachmentType,
      'attachment_id': attachmentId,
      'attachment_title': attachmentTitle,
      'attachment_subtitle': attachmentSubtitle,
      'attachment_club_id': attachmentClubId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> inviteByEmail({
    required ClubModel club,
    required ClubRoom room,
    required UserModel sender,
    required String email,
  }) async {
    final snap = await _db
        .collection('profiles')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      throw Exception('No user found with that email.');
    }
    final userDoc = snap.docs.first;
    await NotificationService().sendRoomInvite(
      userId: userDoc.id,
      senderName: sender.name,
      club: club,
      room: room,
    );
  }

  Future<void> acceptInvite({
    required String roomId,
    required String userId,
  }) async {
    await _rooms.doc(roomId).update({
      'guest_ids': FieldValue.arrayUnion([userId]),
    });
  }
}
