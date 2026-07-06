import 'package:cloud_firestore/cloud_firestore.dart';

class DirectChat {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts;

  const DirectChat({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCounts = const {},
  });

  factory DirectChat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final updatedAt = data['updated_at'];
    return DirectChat(
      id: doc.id,
      participantIds: List<String>.from(data['participant_ids'] ?? const []),
      participantNames: Map<String, String>.from(
        data['participant_names'] ?? const {},
      ),
      lastMessage: data['last_message'] as String? ?? '',
      updatedAt:
          updatedAt is Timestamp ? updatedAt.toDate() : DateTime.now(),
      unreadCounts: Map<String, int>.from(
        (data['unread_counts'] as Map<String, dynamic>? ?? const {})
            .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      ),
    );
  }

  String otherName(String currentUserId) {
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    return participantNames[otherId] ?? 'Chat';
  }

  int unreadFor(String userId) => unreadCounts[userId] ?? 0;
}
