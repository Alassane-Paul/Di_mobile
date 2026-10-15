import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../widgets/avatar_widget.dart';
import 'chat_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Message> _messageResults = [];
  List<Conversation> _conversationResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _messageResults = [];
        _conversationResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final messages = await context.read<ChatProvider>().searchMessages(query);
      await context.read<ChatProvider>().searchUsers(query);

      setState(() {
        _messageResults = messages;
        _conversationResults = [];
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Rechercher',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _search,
          autofocus: true,
        ),
        backgroundColor: const Color(0xFF075E54),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              _search('');
            },
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _messageResults.isEmpty && _conversationResults.isEmpty
              ? const Center(
                  child: Text('Recherchez des messages'),
                )
              : ListView(
                  children: [
                    if (_messageResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Messages',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ..._messageResults.map((message) => _buildMessageTile(message)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildMessageTile(Message message) {
    return ListTile(
      leading: AvatarWidget(
        imageUrl: message.sender.avatar,
        name: message.sender.displayName,
        size: 48,
      ),
      title: Text(message.sender.displayName),
      subtitle: Text(
        message.content ?? 'Média',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTime(message.timestamp),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: message.conversationId,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return '${difference.inHours}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
