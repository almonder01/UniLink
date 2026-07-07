import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String resourceType;
  final String? format;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    this.format,
  });
}

class CloudinaryUploadException implements Exception {
  final String message;

  const CloudinaryUploadException(this.message);

  @override
  String toString() => message;
}

class CloudinaryUploadService {
  Future<CloudinaryUploadResult> uploadPlatformFile(
    PlatformFile file, {
    String resourceType = 'auto',
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const CloudinaryUploadException(
        'Media storage cloud name is missing. Add it in lib/config/cloudinary_config.dart.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '${CloudinaryConfig.cloudName}/$resourceType/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

    if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    } else if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    } else {
      throw const CloudinaryUploadException(
        'Selected file has no readable path or bytes.',
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          data['error'] is Map ? data['error']['message'] : response.reasonPhrase;
      throw CloudinaryUploadException('Media upload failed: $message');
    }

    return CloudinaryUploadResult(
      secureUrl: data['secure_url'] as String,
      publicId: data['public_id'] as String? ?? '',
      resourceType: data['resource_type'] as String? ?? resourceType,
      format: data['format'] as String?,
    );
  }
}
