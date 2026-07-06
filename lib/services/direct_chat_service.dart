import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/direct_chat.dart';
import '../models/user.dart';
import 'club_membership_service.dart';
import 'notification_service.dart';

class DirectChatService {
  static final DirectChatService _instance = DirectChatService._internal();
  factory DirectChatService() => _instance;
  DirectChatService._internal();

  final _db = FirebaseFirestore.instance;
  final _membershipService = ClubMembershipService();

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('direct_chats');

  String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> canMessage({
    required UserModel currentUser,
    required Map<String, dynamic> target,
  }) async {
    final targetId = target['uid'] as String? ?? '';
    if (targetId.isEmpty || targetId == currentUser.id) return false;
    final privacy = target['messagePrivacy'] as String? ?? 'everyone';
    if (privacy != 'club_members') return true;

    final currentClubIds =
        (await _membershipService.memberClubIdsForUser(currentUser.id))
            .toSet();
    if ((currentUser.managedClubId ?? '').isNotEmpty) {
      currentClubIds.add(currentUser.managedClubId!);
    }

    final targetClubIds =
        (await _membershipService.memberClubIdsForUser(targetId)).toSet();
    final targetManagedClubId = target['managedClubId'] as String?;
    if ((targetManagedClubId ?? '').isNotEmpty) {
      targetClubIds.add(targetManagedClubId!);
    }
    return targetClubIds.any(currentClubIds.contains);
  }

  Future<String> startChat({
    required UserModel currentUser,
    required Map<String, dynamic> target,
  }) async {
    final allowed = await canMessage(currentUser: currentUser, target: target);
    if (!allowed) {
      throw Exception('This user only accepts messages from club members.');
    }

    final targetId = target['uid'] as String;
    final chatId = chatIdFor(currentUser.id, targetId);
    await _chats.doc(chatId).set({
      'participant_ids': [currentUser.id, targetId]..sort(),
      'participant_names': {
        currentUser.id: currentUser.name,
        targetId: target['name'] as String? ?? 'Student',
      },
      'participant_photo_base64': {
        currentUser.id: currentUser.photoBase64,
        targetId: target['photoBase64'] as String?,
      },
      'participant_genders': {
        currentUser.id: currentUser.gender,
        targetId: target['gender'] as String?,
      },
      'unread_counts': {
        currentUser.id: 0,
        targetId: 0,
      },
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return chatId;
  }

  Stream<List<DirectChat>> chatsStream(String userId) => _chats
      .where('participant_ids', arrayContains: userId)
      .snapshots()
      .map((snap) {
        final chats = snap.docs.map(DirectChat.fromFirestore).toList();
        chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return chats;
      });

  Future<List<DirectChat>> chatsForUser(String userId) async {
    final snap =
        await _chats.where('participant_ids', arrayContains: userId).get();
    final chats = snap.docs.map(DirectChat.fromFirestore).toList();
    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return chats;
  }

  Stream<List<ChatMessage>> messagesStream(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('created_at')
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());

  Future<void> sendMessage({
    required String chatId,
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
    final chatDoc = await _chats.doc(chatId).get();
    final participantIds = List<String>.from(
      chatDoc.data()?['participant_ids'] ?? const <String>[],
    );
    final batch = _db.batch();
    final messageRef = _chats.doc(chatId).collection('messages').doc();
    batch.set(messageRef, {
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
    batch.set(
      _chats.doc(chatId),
      {
        'last_message': attachmentTitle ?? cleanText,
        'unread_counts': {
          for (final recipientId in participantIds)
            if (recipientId != sender.id)
              recipientId: FieldValue.increment(1),
        },
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    final preview = attachmentTitle ?? cleanText;
    for (final recipientId in participantIds) {
      if (recipientId == sender.id) continue;
      NotificationService()
          .sendDirectMessageNotification(
            recipientId: recipientId,
            sender: sender,
            chatId: chatId,
            preview: preview,
          )
          .catchError((_) {});
    }
  }

  Future<void> markRead({
    required String chatId,
    required String userId,
  }) async {
    await _chats.doc(chatId).set({
      'unread_counts': {userId: 0},
    }, SetOptions(merge: true));
  }

  Stream<int> unreadTotalStream(String userId) {
    return chatsStream(userId).map(
      (chats) => chats.fold<int>(
        0,
        (total, chat) => total + chat.unreadFor(userId),
      ),
    );
  }
}
