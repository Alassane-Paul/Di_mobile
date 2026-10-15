import 'user.dart';

class Story {
  final int id;
  final int userId;
  final String mediaUrl;
  final String mediaType; // image or video
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<StoryViewer> viewers;
  final User user;

  Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewers,
    required this.user,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      userId: json['userId'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'] ?? 'image',
      caption: json['caption'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      viewers: (json['viewers'] as List?)
              ?.map((v) => StoryViewer.fromJson(v))
              .toList() ??
          [],
      user: User.fromJson(json['user']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';
  int get viewerCount => viewers.length;
}

class StoryViewer {
  final int userId;
  final String username;
  final String displayName;
  final DateTime viewedAt;

  StoryViewer({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.viewedAt,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      userId: json['userId'],
      username: json['username'],
      displayName: json['displayName'],
      viewedAt: DateTime.parse(json['viewedAt']),
    );
  }
}
