import 'user.dart';

class Call {
  final int id;
  final int conversationId;
  final User caller;
  final String type; // audio or video
  final String status; // initiated, ringing, connected, ended, rejected, missed
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration;

  Call({
    required this.id,
    required this.conversationId,
    required this.caller,
    required this.type,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'],
      conversationId: json['conversationId'],
      caller: User.fromJson(json['caller']),
      type: json['type'] ?? 'audio',
      status: json['status'] ?? 'initiated',
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      duration: json['duration'],
    );
  }

  bool get isAudio => type == 'audio';
  bool get isVideo => type == 'video';
  bool get isMissed => status == 'missed';
  bool get isRejected => status == 'rejected';
  bool get isConnected => status == 'connected';
  bool get isEnded => status == 'ended';

  String get durationText {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
