import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club.dart';

class ClubService {
  static final ClubService _instance = ClubService._internal();
  factory ClubService() => _instance;
  ClubService._internal();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('clubs');

  Stream<List<ClubModel>> clubsStream() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(ClubModel.fromFirestore).toList());

  Future<ClubModel?> getClubById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? ClubModel.fromFirestore(doc) : null;
  }

  Future<void> updateClub(ClubModel club) async {
    await _col.doc(club.id).update(club.toFirestore());
    await _syncClubIdentity(club);
  }

  Future<void> updateClubData({
    required String clubId,
    required Map<String, dynamic> data,
  }) async {
    await _col.doc(clubId).update(data);

    final identityData = <String, dynamic>{};
    if (data.containsKey('name')) {
      identityData['clubName'] = data['name'] as String? ?? '';
    }
    if (data.containsKey('logo_color')) {
      identityData['clubLogoColor'] =
          data['logo_color'] as String? ?? 'FF6366F1';
    }
    if (data.containsKey('logo_image_base64')) {
      identityData['clubLogoImageBase64'] =
          data['logo_image_base64'] as String? ?? '';
    }
    if (data.containsKey('show_logo_background')) {
      identityData['clubShowLogoBackground'] =
          data['show_logo_background'] as bool? ?? true;
    }
    if (identityData.isEmpty) return;

    await _syncClubIdentityFields(clubId: clubId, data: identityData);
  }

  Future<void> _syncClubIdentity(ClubModel club) async {
    final data = {
      'clubName': club.name,
      'clubLogoColor': club.logoColor,
      'clubLogoImageBase64': club.logoImageBase64 ?? '',
      'clubShowLogoBackground': club.showLogoBackground,
    };

    await _syncClubIdentityFields(clubId: club.id, data: data);
  }

  Future<void> _syncClubIdentityFields({
    required String clubId,
    required Map<String, dynamic> data,
  }) async {
    await _syncCollectionClubIdentity(
      collection: 'posts',
      clubId: clubId,
      data: data,
    );
    await _syncCollectionClubIdentity(
      collection: 'events',
      clubId: clubId,
      data: data,
    );
  }

  Future<void> _syncCollectionClubIdentity({
    required String collection,
    required String clubId,
    required Map<String, dynamic> data,
  }) async {
    final snap =
        await _db.collection(collection).where('clubId', isEqualTo: clubId).get();
    if (snap.docs.isEmpty) return;

    WriteBatch batch = _db.batch();
    var pending = 0;
    for (final doc in snap.docs) {
      batch.update(doc.reference, data);
      pending++;
      if (pending == 450) {
        await batch.commit();
        batch = _db.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();
  }

  /// Seeds the 8 default clubs into Firestore if the collection is empty.
  /// Must be called while a user is authenticated.
  Future<void> seedIfEmpty() async {
    final existing = await _col.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final club in _defaultClubs) {
      final id = club['id'] as String;
      final data = Map<String, dynamic>.from(club)..remove('id');
      batch.set(_col.doc(id), data);
    }
    await batch.commit();
  }

  static final List<Map<String, dynamic>> _defaultClubs = [
    {
      'id': 'cs_club',
      'name': 'Computer Science Club',
      'description':
          'A vibrant community for tech enthusiasts to explore programming, AI, web development, and innovation. We host weekly coding sessions, hackathons, and industry talks.',
      'category': 'Tech',
      'logo_color': 'FF6366F1',
      'manager_name': 'Jordan Lee',
      'member_count': 342,
    },
    {
      'id': 'chess_club',
      'name': 'Chess Club',
      'description':
          'Sharpen your analytical mind through the timeless game of strategy and skill. Open to all levels from beginners to tournament players.',
      'category': 'Academic',
      'logo_color': 'FF10B981',
      'manager_name': 'Sam Chen',
      'member_count': 78,
    },
    {
      'id': 'photo_soc',
      'name': 'Photography Society',
      'description':
          "Capture life's most beautiful moments through the lens. We do workshops, photo walks, exhibitions and competitions. All skill levels welcome!",
      'category': 'Arts',
      'logo_color': 'FFF59E0B',
      'manager_name': 'Maya Patel',
      'member_count': 156,
    },
    {
      'id': 'drama_club',
      'name': 'Drama Club',
      'description':
          'Express yourself on the stage and screen. We produce theatre productions, short films, and improv shows every semester.',
      'category': 'Arts',
      'logo_color': 'FFEF4444',
      'manager_name': 'Chris Wong',
      'member_count': 92,
    },
    {
      'id': 'basketball_club',
      'name': 'Basketball Club',
      'description':
          'Competitive and recreational basketball for all students. Join us for training, inter-university tournaments and social matches.',
      'category': 'Sports',
      'logo_color': 'FFFF6B35',
      'manager_name': 'Tyler Brooks',
      'member_count': 210,
    },
    {
      'id': 'mun_club',
      'name': 'Model United Nations',
      'description':
          'Develop leadership, diplomacy, research, and public speaking skills through MUN conferences. Represent countries, debate global issues, and build resolutions.',
      'category': 'Academic',
      'logo_color': 'FF3B82F6',
      'manager_name': 'Priya Sharma',
      'member_count': 127,
    },
    {
      'id': 'env_club',
      'name': 'Environmental Club',
      'description':
          'Making our campus greener one initiative at a time. We run tree-planting drives, recycling programs, awareness campaigns and sustainability workshops.',
      'category': 'Environment',
      'logo_color': 'FF22C55E',
      'manager_name': 'Emma Liu',
      'member_count': 88,
    },
    {
      'id': 'music_soc',
      'name': 'Music Society',
      'description':
          'Unite through the universal language of music. We host jam sessions, concerts, songwriting workshops and open mic nights for all genres and instruments.',
      'category': 'Music',
      'logo_color': 'FFA855F7',
      'manager_name': 'Kai Nakamura',
      'member_count': 175,
    },
  ];
}
