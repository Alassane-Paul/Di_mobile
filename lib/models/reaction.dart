import 'user.dart';

class MessageReaction {
  final int id;
  final int messageId;
  final User user;
  final String emoji;
  final DateTime createdAt;

  MessageReaction({
    required this.id,
    required this.messageId,
    required this.user,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] ?? 0,
      messageId: json['messageId'] ?? 0,
      user: json['user'] != null
          ? User.fromJson(json['user'])
          : User(id: 0, username: '', displayName: 'Unknown'),
      emoji: json['emoji'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
