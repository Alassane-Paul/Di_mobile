class User {
  final int id;
  final String username;
  final String? email;
  final String displayName;
  final String? avatar;
  final String? status;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? publicKey;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.displayName,
    this.avatar,
    this.status,
    this.isOnline = false,
    this.lastSeen,
    this.publicKey,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'],
      displayName: json['displayName'] ?? json['username'] ?? '',
      avatar: json['avatar'],
      status: json['status'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      publicKey: json['publicKey'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatar': avatar,
      'status': status,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'publicKey': publicKey,
    };
  }
}

