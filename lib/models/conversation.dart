import 'message.dart';
import 'user.dart';

class Conversation {
  final int id;
  final String type;
  final String? name;
  final String? avatar;
  final String? description;
  final int? createdBy;
  final Message? lastMessage;
  final DateTime? lastMessageAt;
  final bool isArchived;
  final bool isPinned;
  final List<User> participants;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    this.description,
    this.createdBy,
    this.lastMessage,
    this.lastMessageAt,
    this.isArchived = false,
    this.isPinned = false,
    required this.participants,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      type: json['type'] ?? 'direct',
      name: json['name'],
      avatar: json['avatar'],
      description: json['description'],
      createdBy: json['createdBy'],
      lastMessage: json['lastMessage'] != null ? Message.fromJson(json['lastMessage']) : null,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : null,
      isArchived: json['isArchived'] ?? false,
      isPinned: json['isPinned'] ?? false,
      participants: (json['participants'] as List?)
              ?.map((p) => User.fromJson(p))
              .toList() ??
          [],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  bool get isGroup => type == 'group';
  bool get isDirect => type == 'direct';

  String get displayName {
    if (isGroup) return name ?? 'Groupe';
    if (participants.length >= 2) {
      final otherUser = participants.firstWhere((p) => p.id != createdBy, orElse: () => participants.first);
      return otherUser.displayName;
    }
    return 'Conversation';
  }

  String? get displayAvatar {
    if (isGroup) return avatar;
    if (participants.length >= 2) {
      final otherUser = participants.firstWhere((p) => p.id != createdBy, orElse: () => participants.first);
      return otherUser.avatar;
    }
    return null;
  }

  String get lastMessageText {
    if (lastMessage == null) return 'Aucun message';
    if (lastMessage!.isMedia) {
      switch (lastMessage!.messageType) {
        case 'image':
          return '📷 Photo';
        case 'video':
          return '🎥 Vidéo';
        case 'audio':
        case 'voice':
          return '🎤 Audio';
        case 'document':
          return '📄 Document';
        case 'location':
          return '📍 Localisation';
        case 'contact':
          return '👤 Contact';
        default:
          return '📎 Fichier';
      }
    }
    return lastMessage!.content ?? '';
  }
}
