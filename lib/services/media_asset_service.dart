import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/media_asset.dart';

class MediaAssetService {
  static final MediaAssetService _instance = MediaAssetService._internal();
  factory MediaAssetService() => _instance;
  MediaAssetService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _assets =>
      _db.collection('media_assets');

  Future<List<MediaAsset>> getAssetsForClub(String clubId) async {
    final snap = await _assets.where('club_id', isEqualTo: clubId).get();
    final assets = snap.docs
        .map((doc) => MediaAsset.fromMap(doc.data()))
        .where((asset) => asset.url.trim().isNotEmpty)
        .toList();
    assets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return assets;
  }

  Future<void> saveFromUrl({
    required String clubId,
    required String name,
    required String url,
    required String mediaKind,
    required String sourceType,
    String? createdBy,
  }) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    final id = idFor(
      clubId: clubId,
      url: cleanUrl,
      mediaKind: mediaKind,
      sourceType: sourceType,
    );
    final doc = await _assets.doc(id).get();
    if (doc.exists) return;

    final asset = MediaAsset(
      id: id,
      clubId: clubId,
      name: name.trim().isEmpty ? _defaultName(mediaKind, sourceType) : name,
      url: cleanUrl,
      mediaKind: mediaKind,
      sourceType: sourceType,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    await _assets.doc(id).set(asset.toMap());
  }

  Future<void> updateName({
    required String assetId,
    required String name,
  }) {
    return _assets.doc(assetId).update({'name': name.trim()});
  }

  static String idFor({
    required String clubId,
    required String url,
    required String mediaKind,
    required String sourceType,
  }) {
    final raw = '$clubId|$mediaKind|$sourceType|${url.trim()}';
    return 'media_${base64Url.encode(utf8.encode(raw)).replaceAll('=', '')}';
  }

  static String _defaultName(String mediaKind, String sourceType) {
    if (mediaKind == 'audio') {
      return sourceType == 'youtube' ? 'YouTube music' : 'Uploaded music';
    }
    return sourceType == 'youtube' ? 'YouTube video' : 'Uploaded video';
  }
}
