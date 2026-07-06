import 'package:cloud_firestore/cloud_firestore.dart';

class ClubRoom {
  final String id;
  final String clubId;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final List<String> guestIds;
  final bool isDefault;
  final String? imageBase64;

  const ClubRoom({
    required this.id,
    required this.clubId,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.guestIds = const [],
    this.isDefault = false,
    this.imageBase64,
  });

  factory ClubRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['created_at'];
    return ClubRoom(
      id: doc.id,
      clubId: data['club_id'] as String? ?? '',
      name: data['name'] as String? ?? 'General',
      createdBy: data['created_by'] as String? ?? '',
      createdAt:
          createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      guestIds: List<String>.from(data['guest_ids'] ?? const []),
      isDefault: data['is_default'] as bool? ?? false,
      imageBase64: data['image_base64'] as String?,
    );
  }

  ClubRoom copyWith({
    String? name,
    String? imageBase64,
  }) {
    return ClubRoom(
      id: id,
      clubId: clubId,
      name: name ?? this.name,
      createdBy: createdBy,
      createdAt: createdAt,
      guestIds: guestIds,
      isDefault: isDefault,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
