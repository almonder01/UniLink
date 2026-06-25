import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String logoColor; // 8-char hex, e.g. "FF6366F1"
  final String? managerId;
  final String? managerName;
  final int memberCount;

  const ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.logoColor,
    this.managerId,
    this.managerName,
    required this.memberCount,
  });

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClubModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: d['category'] as String? ?? '',
      logoColor: d['logo_color'] as String? ?? 'FF6366F1',
      managerId: d['manager_id'] as String?,
      managerName: d['manager_name'] as String?,
      memberCount: (d['member_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'category': category,
        'logo_color': logoColor,
        if (managerId != null) 'manager_id': managerId,
        if (managerName != null) 'manager_name': managerName,
        'member_count': memberCount,
      };

  ClubModel copyWith({String? managerId, String? managerName}) {
    return ClubModel(
      id: id,
      name: name,
      description: description,
      category: category,
      logoColor: logoColor,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      memberCount: memberCount,
    );
  }
}
