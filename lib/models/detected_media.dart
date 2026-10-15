class DetectedMedia {
  final int id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String fileType; // image, video, audio
  final DateTime uploadedAt;
  final bool processed;
  final int? userId;

  DetectedMedia({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
    this.processed = false,
    this.userId,
  });

  factory DetectedMedia.fromJson(Map<String, dynamic> json) {
    return DetectedMedia(
      id: json['id'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      fileType: json['fileType'] ?? 'image',
      uploadedAt: DateTime.parse(json['uploadedAt']),
      processed: json['processed'] ?? false,
      userId: json['userId'],
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isImage => fileType == 'image';
  bool get isVideo => fileType == 'video';
  bool get isAudio => fileType == 'audio';
}
