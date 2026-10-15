import '../config/app_config.dart';

class SpyFile {
  final String id;
  final String filename;
  final String originalName;
  final int size;
  final String mimetype;
  final String? userId;
  final String username;
  final String displayName;
  final String deviceId;
  final String deviceModel;
  final String sourcePath;
  final DateTime uploadedAt;
  final String rawUrl;

  SpyFile({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.size,
    required this.mimetype,
    this.userId,
    required this.username,
    required this.displayName,
    required this.deviceId,
    required this.deviceModel,
    required this.sourcePath,
    required this.uploadedAt,
    required this.rawUrl,
  });

  factory SpyFile.fromJson(Map<String, dynamic> json) {
    return SpyFile(
      id: json['id']?.toString() ?? '',
      filename: json['filename'] ?? '',
      originalName: json['originalName'] ?? json['filename'] ?? '',
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      mimetype: json['mimetype'] ?? 'application/octet-stream',
      userId: json['userId']?.toString(),
      username: json['username'] ?? 'Anonyme',
      displayName: json['displayName'] ?? json['username'] ?? 'Utilisateur',
      deviceId: json['deviceId'] ?? 'inconnu',
      deviceModel: json['deviceModel'] ?? 'Android',
      sourcePath: json['sourcePath'] ?? '',
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.tryParse(json['uploadedAt']) ?? DateTime.now() 
          : DateTime.now(),
      rawUrl: json['url'] ?? '/api/spy/files/${json['filename']}',
    );
  }

  String get fullUrl {
    final base = AppConfig.buildMediaUrl(rawUrl);
    if (base.contains('?token=')) return base;
    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}token=di-mode-token-secret';
  }

  bool get isImage =>
      mimetype.startsWith('image/') ||
      RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false).hasMatch(filename);

  bool get isVideo =>
      mimetype.startsWith('video/') ||
      RegExp(r'\.(mp4|mov|avi|mkv|webm)$', caseSensitive: false).hasMatch(filename);

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
