import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/call.dart';
import '../models/story.dart';
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  final _storage = const FlutterSecureStorage();

  static List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      if (body['data'] is List) return body['data'] as List<dynamic>;
    }
    return [];
  }

  static Map<String, dynamic> _extractMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['data'] is List && (body['data'] as List).isNotEmpty && body['data'][0] is Map) {
        return body['data'][0] as Map<String, dynamic>;
      }
      if (body['data'] is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>;
      }
      return body;
    }
    return {};
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final token = data['token'] ?? (data['data'] is List && (data['data'] as List).isNotEmpty ? data['data'][0]['token'] : null);
      final user = data['user'] ?? (data['data'] is List && (data['data'] as List).isNotEmpty ? data['data'][0]['user'] : null);
      await _storage.write(key: 'token', value: token?.toString());
      await _storage.write(key: 'user', value: jsonEncode(user));
    } else {
      throw Exception(data['error'] ?? data['responseMessage'] ?? 'Login failed');
    }
  }

  Future<void> register(String username, String email, String password, String displayName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final token = data['token'] ?? (data['data'] is List && (data['data'] as List).isNotEmpty ? data['data'][0]['token'] : null);
      final user = data['user'] ?? (data['data'] is List && (data['data'] as List).isNotEmpty ? data['data'][0]['user'] : null);
      await _storage.write(key: 'token', value: token?.toString());
      await _storage.write(key: 'user', value: jsonEncode(user));
    } else {
      throw Exception(data['error'] ?? data['responseMessage'] ?? 'Registration failed');
    }
  }

  Future<User> getProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(_extractMap(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to get profile');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/search?query=$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _extractList(jsonDecode(response.body));
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  // Conversations
  Future<List<Conversation>> getConversations() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _extractList(jsonDecode(response.body));
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get conversations');
    }
  }

  Future<Conversation> createConversation(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Conversation.fromJson(_extractMap(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to create conversation');
    }
  }

  Future<void> archiveConversation(int conversationId, bool archive) async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/conversations/$conversationId/archive'),
      headers: headers,
      body: jsonEncode({'archive': archive}),
    );
  }

  Future<void> pinConversation(int conversationId, bool pin) async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/conversations/$conversationId/pin'),
      headers: headers,
      body: jsonEncode({'pin': pin}),
    );
  }

  Future<void> muteConversation(int conversationId, String? mutedUntil) async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/conversations/$conversationId/mute'),
      headers: headers,
      body: jsonEncode({'mutedUntil': mutedUntil}),
    );
  }

  // Messages
  Future<List<Message>> getMessages(int conversationId, {int? beforeMessageId, int limit = 50}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/messages/conversation/$conversationId?limit=$limit';
    if (beforeMessageId != null) {
      url += '&beforeMessageId=$beforeMessageId';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = _extractList(jsonDecode(response.body));
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get messages');
    }
  }

  Future<Message> createMessage(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Message.fromJson(_extractMap(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to create message');
    }
  }

  Future<Message> editMessage(int messageId, String content) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return Message.fromJson(_extractMap(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to edit message');
    }
  }

  Future<void> deleteMessage(int messageId, bool deleteForEveryone) async {
    final headers = await _getHeaders();
    await http.delete(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: headers,
      body: jsonEncode({'deleteForEveryone': deleteForEveryone}),
    );
  }

  Future<void> markAsRead(int conversationId, int lastMessageId) async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/messages/conversation/$conversationId/read'),
      headers: headers,
      body: jsonEncode({'lastMessageId': lastMessageId}),
    );
  }

  Future<void> addReaction(int messageId, String emoji) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/messages/$messageId/reaction'),
      headers: headers,
      body: jsonEncode({'emoji': emoji}),
    );
  }

  Future<List<Message>> searchMessages(String query, {int? conversationId}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/messages/search?query=$query';
    if (conversationId != null) {
      url += '&conversationId=$conversationId';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = _extractList(jsonDecode(response.body));
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search messages');
    }
  }

  // Calls
  Future<Call> initiateCall(int conversationId, String type) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/calls'),
      headers: headers,
      body: jsonEncode({
        'conversationId': conversationId,
        'type': type,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Call.fromJson(_extractMap(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to initiate call');
    }
  }

  Future<void> updateCallStatus(int callId, String status) async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/calls/$callId/status'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );
  }

  Future<List<Call>> getCallHistory() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/calls/history'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _extractList(jsonDecode(response.body));
      return data.map((json) => Call.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get call history');
    }
  }

  // Upload
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final data = jsonDecode(await response.stream.bytesToString());

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Upload failed');
    }
  }

  Future<Map<String, dynamic>> uploadFileBytes(String filename, List<int> bytes) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final response = await request.send();
    final data = jsonDecode(await response.stream.bytesToString());

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Upload failed');
    }
  }

  // Stories
  Future<List<Story>> getStories() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/stories'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = _extractList(jsonDecode(response.body));
      return data.map((json) => Story.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get stories');
    }
  }

  Future<Story> createStory(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/stories'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Story.fromJson(_extractMap(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to create story');
    }
  }

  Future<void> viewStory(int storyId) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/stories/$storyId/view'),
      headers: headers,
    );
  }

  Future<void> deleteStory(int storyId) async {
    final headers = await _getHeaders();
    await http.delete(
      Uri.parse('$baseUrl/stories/$storyId'),
      headers: headers,
    );
  }

  Future<bool> checkAuth() async {
    final token = await _getToken();
    return token != null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }

  Future<Map<String, String>> _getSpyHeaders() async {
    final headers = await _getHeaders();
    headers['x-spy-token'] = 'di-mode-token-secret';
    return headers;
  }

  // Spy API (Sécurisé par JWT et Secret Token)
  Future<Map<String, dynamic>> getSpyFiles({String? userId, String? sortBy}) async {
    final queryParams = <String, String>{};
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;

    final uri = Uri.parse('$baseUrl/spy/files').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final headers = await _getSpyHeaders();
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur chargement fichiers spy: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getSpyStats() async {
    final headers = await _getSpyHeaders();
    final response = await http.get(Uri.parse('$baseUrl/spy/stats'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur chargement statistiques spy');
    }
  }

  Future<void> deleteSpyFile(String filename) async {
    final headers = await _getSpyHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/spy/files/$filename'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression fichier spy');
    }
  }
}
