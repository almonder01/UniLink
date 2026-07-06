import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String logoColor; // 8-char hex, e.g. "FF6366F1"
  final String? logoImageBase64;
  final bool showLogoBackground;
  final String? imageBase64;
  final List<String> galleryBase64List;
  final String? managerId;
  final String? managerName;
  final int memberCount;

  const ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.logoColor,
    this.logoImageBase64,
    this.showLogoBackground = true,
    this.imageBase64,
    this.galleryBase64List = const [],
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
      logoImageBase64: d['logo_image_base64'] as String?,
      showLogoBackground: d['show_logo_background'] as bool? ?? true,
      imageBase64: d['image_base64'] as String?,
      galleryBase64List:
          List<String>.from(d['gallery_base64_list'] ?? const []),
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
        if (logoImageBase64 != null) 'logo_image_base64': logoImageBase64,
        'show_logo_background': showLogoBackground,
        if (imageBase64 != null) 'image_base64': imageBase64,
        'gallery_base64_list': galleryBase64List,
        if (managerId != null) 'manager_id': managerId,
        if (managerName != null) 'manager_name': managerName,
        'member_count': memberCount,
      };

  ClubModel copyWith({
    String? name,
    String? description,
    String? logoColor,
    String? logoImageBase64,
    bool? showLogoBackground,
    String? imageBase64,
    List<String>? galleryBase64List,
    String? managerId,
    String? managerName,
  }) {
    return ClubModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category,
      logoColor: logoColor ?? this.logoColor,
      logoImageBase64: logoImageBase64 ?? this.logoImageBase64,
      showLogoBackground: showLogoBackground ?? this.showLogoBackground,
      imageBase64: imageBase64 ?? this.imageBase64,
      galleryBase64List: galleryBase64List ?? this.galleryBase64List,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      memberCount: memberCount,
    );
  }
}
