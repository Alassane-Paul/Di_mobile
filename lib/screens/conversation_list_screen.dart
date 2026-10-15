import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../widgets/avatar_widget.dart';
import 'chat_detail_screen.dart';
import 'new_conversation_screen.dart';

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatProvider.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune conversation',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewConversationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle conversation'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chatProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversation = chatProvider.conversations[index];
            return _buildConversationTile(context, conversation, chatProvider);
          },
        );
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    return ListTile(
      leading: AvatarWidget(
        imageUrl: conversation.displayAvatar,
        name: conversation.displayName,
        size: 56,
        showOnlineStatus: true,
        isOnline: conversation.participants.any((p) => p.isOnline),
      ),
      title: Text(
        conversation.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (conversation.isPinned)
            const Icon(Icons.push_pin, size: 14, color: Color(0xFF075E54)),
          if (conversation.isPinned) const SizedBox(width: 4),
          Expanded(
            child: Text(
              conversation.lastMessageText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? Colors.black87
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: conversation.unreadCount > 0
                    ? const Color(0xFF075E54)
                    : Colors.grey[600],
              ),
            ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conversation.id,
              conversation: conversation,
            ),
          ),
        );
      },
      onLongPress: () {
        _showConversationOptions(context, conversation, chatProvider);
      },
    );
  }

  void _showConversationOptions(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conversation.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(conversation.isPinned ? 'Désépingler' : 'Épingler'),
              onTap: () {
                Navigator.pop(context);
                chatProvider.pinConversation(conversation.id, !conversation.isPinned);
              },
            ),
            ListTile(
              leading: Icon(
                conversation.isArchived ? Icons.unarchive : Icons.archive,
              ),
              title: Text(conversation.isArchived ? 'Désarchiver' : 'Archiver'),
              onTap: () {
                Navigator.pop(context);
                chatProvider.archiveConversation(conversation.id, !conversation.isArchived);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mettre en sourdine'),
              onTap: () async {
                Navigator.pop(context);
                final mutedUntil = DateTime.now().add(const Duration(hours: 8)).toIso8601String();
                await chatProvider.muteConversation(conversation.id, mutedUntil);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Discussion mise en sourdine pour 8 heures')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer la discussion', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer la discussion ?'),
                    content: const Text('Cette action supprimera votre historique de conversation.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await chatProvider.archiveConversation(conversation.id, true);
                  await chatProvider.loadConversations();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Maintenant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${dateTime.weekday}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
