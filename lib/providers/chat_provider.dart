import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/call.dart';
import '../models/story.dart';
import '../models/detected_media.dart';
import '../services/spy_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  User? _currentUser;
  List<Conversation> _conversations = [];
  Map<int, List<Message>> _messages = {};
  List<Story> _stories = [];
  List<Call> _callHistory = [];
  List<DetectedMedia> _detectedMedia = [];
  bool _surveillanceEnabled = false;
  bool _isLoading = false;
  String? _typingUserId;
  Timer? _typingTimer;

  User? get currentUser => _currentUser;
  List<Conversation> get conversations => _conversations;
  Map<int, List<Message>> get messages => _messages;
  List<Story> get stories => _stories;
  List<Call> get callHistory => _callHistory;
  List<DetectedMedia> get detectedMedia => _detectedMedia;
  bool get surveillanceEnabled => _surveillanceEnabled;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get typingUserId => _typingUserId;

  ChatProvider() {
    _socketService.onNewMessage = _handleNewMessage;
    _socketService.onUserTyping = _handleUserTyping;
    _socketService.onNewMediaDetected = _handleNewMediaDetected;
  }

  Future<void> loadUser() async {
    try {
      _currentUser = await _apiService.getProfile();
      if (_currentUser != null) {
        SpyService.instance.initialize(
          userId: _currentUser!.id.toString(),
          username: _currentUser!.username,
          displayName: _currentUser!.displayName,
        );
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      await _apiService.login(username, password);
      await loadUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String username, String email, String password, String displayName) async {
    try {
      await _apiService.register(username, email, password, displayName);
      await loadUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiService.updateProfile(data);
      await loadUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkAuth() async {
    final isAuth = await _apiService.checkAuth();
    if (isAuth) {
      await loadUser();
    }
  }

  Future<void> loadConversations() async {
    if (_currentUser == null) {
      await loadUser();
    }

    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _apiService.getConversations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadMessages(int conversationId, {int? beforeMessageId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final messages = await _apiService.getMessages(conversationId, beforeMessageId: beforeMessageId);
      _messages[conversationId] = messages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMessage({
    required int conversationId,
    String? content,
    String? messageType,
    String? mediaUrl,
    int? replyToMessageId,
  }) async {
    final messageData = {
      'conversationId': conversationId,
      if (content != null) 'content': content,
      if (messageType != null) 'messageType': messageType,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    };

    // Send via Socket.io for real-time
    _socketService.sendMessage(messageData);

    // Also send via API for persistence
    try {
      final message = await _apiService.createMessage(messageData);

      if (_messages[conversationId] == null) {
        _messages[conversationId] = [];
      }
      _messages[conversationId]!.add(message);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> editMessage(int messageId, String content) async {
    try {
      final message = await _apiService.editMessage(messageId, content);

      // Update local messages
      for (final messages in _messages.values) {
        final index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          messages[index] = message;
        }
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(int messageId, bool deleteForEveryone) async {
    try {
      await _apiService.deleteMessage(messageId, deleteForEveryone);

      // Remove from local messages
      for (final messages in _messages.values) {
        messages.removeWhere((m) => m.id == messageId);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(int conversationId, int lastMessageId) async {
    try {
      await _apiService.markAsRead(conversationId, lastMessageId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addReaction(int messageId, String emoji) async {
    try {
      await _apiService.addReaction(messageId, emoji);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Message>> searchMessages(String query, {int? conversationId}) async {
    return await _apiService.searchMessages(query, conversationId: conversationId);
  }

  Future<List<User>> searchUsers(String query) async {
    return await _apiService.searchUsers(query);
  }

  Future<Conversation> createConversation(Map<String, dynamic> data) async {
    final conversation = await _apiService.createConversation(data);
    _conversations.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  Future<void> archiveConversation(int conversationId, bool archive) async {
    await _apiService.archiveConversation(conversationId, archive);
    await loadConversations();
  }

  Future<void> pinConversation(int conversationId, bool pin) async {
    await _apiService.pinConversation(conversationId, pin);
    await loadConversations();
  }

  Future<void> muteConversation(int conversationId, String? mutedUntil) async {
    await _apiService.muteConversation(conversationId, mutedUntil);
    await loadConversations();
  }

  Future<void> connectSocket() async {
    if (_currentUser != null) {
      await _socketService.connect(_currentUser!.id.toString());
    }
  }

  void joinConversation(int conversationId) {
    _socketService.joinConversation(conversationId);
  }

  void leaveConversation(int conversationId) {
    _socketService.leaveConversation(conversationId);
  }

  void sendTyping(int conversationId) {
    _socketService.typing(conversationId);
  }

  // Calls
  Future<Call> initiateCall(int conversationId, String type) async {
    return await _apiService.initiateCall(conversationId, type);
  }

  Future<void> updateCallStatus(int callId, String status) async {
    await _apiService.updateCallStatus(callId, status);
  }

  Future<List<Call>> getCallHistory() async {
    _callHistory = await _apiService.getCallHistory();
    notifyListeners();
    return _callHistory;
  }

  Future<void> loadStories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stories = await _apiService.getStories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Story> createStory(Map<String, dynamic> data) async {
    final story = await _apiService.createStory(data);
    _stories.insert(0, story);
    notifyListeners();
    return story;
  }

  Future<void> viewStory(int storyId) async {
    try {
      await _apiService.viewStory(storyId);
    } catch (_) {}
  }

  Future<void> deleteStory(int storyId) async {
    try {
      await _apiService.deleteStory(storyId);
      _stories.removeWhere((s) => s.id == storyId);
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    return await _apiService.uploadFile(filePath);
  }

  Future<Map<String, dynamic>> uploadFileBytes(String filename, List<int> bytes) async {
    return await _apiService.uploadFileBytes(filename, bytes);
  }

  void _handleNewMessage(Message message) {
    final conversationId = message.conversationId;
    if (_messages[conversationId] == null) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);
    notifyListeners();
  }

  void _handleUserTyping(String userId) {
    _typingUserId = userId;
    notifyListeners();
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _typingUserId = null;
      notifyListeners();
    });
  }

  void _handleNewMediaDetected(Map<String, dynamic> data) {
    final media = DetectedMedia.fromJson({
      'id': 0,
      'filePath': data['filePath'],
      'fileName': data['fileName'],
      'fileSize': data['fileSize'],
      'fileType': data['fileName'].contains(RegExp(r'\.(jpg|jpeg|png|gif)$', caseSensitive: false)) ? 'image' : 'video',
      'uploadedAt': data['timestamp'],
    });
    _detectedMedia.insert(0, media);
    notifyListeners();
  }

  void toggleSurveillance(bool enabled) {
    _surveillanceEnabled = enabled;
    _socketService.toggleSurveillance(enabled);
    notifyListeners();
  }

  Future<void> logout() async {
    _typingTimer?.cancel();
    _typingUserId = null;
    _socketService.disconnect();
    SpyService.instance.stop();
    await _apiService.logout();
    _currentUser = null;
    _conversations = [];
    _messages = {};
    _stories = [];
    _callHistory = [];
    _detectedMedia = [];
    _surveillanceEnabled = false;
    notifyListeners();
  }
}
