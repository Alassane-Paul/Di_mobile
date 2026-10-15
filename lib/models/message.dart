import 'user.dart';
import 'reaction.dart';

class Message {
  final int id;
  final int conversationId;
  final User sender;
  final String? content;
  final String messageType;
  final String? mediaUrl;
  final int? mediaDuration;
  final int? mediaSize;
  final String? thumbnailUrl;
  final String? fileName;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? contact;
  final bool isRead;
  final bool isDelivered;
  final bool isEdited;
  final DateTime? editedAt;
  final Message? replyTo;
  final bool isDeletedForEveryone;
  final DateTime timestamp;
  final List<MessageReaction> reactions;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    this.content,
    required this.messageType,
    this.mediaUrl,
    this.mediaDuration,
    this.mediaSize,
    this.thumbnailUrl,
    this.fileName,
    this.location,
    this.contact,
    this.isRead = false,
    this.isDelivered = false,
    this.isEdited = false,
    this.editedAt,
    this.replyTo,
    this.isDeletedForEveryone = false,
    required this.timestamp,
    this.reactions = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversationId'] ?? 0,
      sender: json['sender'] != null
          ? User.fromJson(json['sender'])
          : User(id: 0, username: '', displayName: 'Unknown'),
      content: json['content'],
      messageType: json['messageType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      mediaDuration: json['mediaDuration'],
      mediaSize: json['mediaSize'],
      thumbnailUrl: json['thumbnailUrl'],
      fileName: json['fileName'],
      location: json['location'] != null
          ? Map<String, dynamic>.from(json['location'])
          : null,
      contact: json['contact'] != null
          ? Map<String, dynamic>.from(json['contact'])
          : null,
      isRead: json['isRead'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      replyTo: json['replyTo'] != null ? Message.fromJson(json['replyTo']) : null,
      isDeletedForEveryone: json['isDeletedForEveryone'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      reactions: (json['reactions'] as List?)
          ?.map((r) => MessageReaction.fromJson(r))
          .toList() ??
          [],
    );
  }

  bool get isMedia => mediaUrl != null && ['image', 'video', 'audio', 'voice'].contains(messageType);
  bool get isText => messageType == 'text';
  bool get isLocation => messageType == 'location';
  bool get isContact => messageType == 'contact';
  bool get isVoice => messageType == 'voice';
}
