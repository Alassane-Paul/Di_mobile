import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/reaction_picker.dart';
import 'call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final int conversationId;
  final Conversation? conversation;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  Message? _replyingTo;
  Message? _editingMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.conversationId);
      context.read<ChatProvider>().connectSocket();
      context.read<ChatProvider>().joinConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatProvider>().leaveConversation(widget.conversationId);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (_editingMessage != null) {
      await context.read<ChatProvider>().editMessage(_editingMessage!.id, content);
      setState(() {
        _editingMessage = null;
        _messageController.clear();
      });
      return;
    }

    final replyId = _replyingTo?.id;

    await context.read<ChatProvider>().sendMessage(
          conversationId: widget.conversationId,
          content: content,
          replyToMessageId: replyId,
        );

    setState(() {
      _replyingTo = null;
    });
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? image = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (image == null) return;

    try {
      final uploadResult = await context.read<ChatProvider>().uploadFile(image.path);
      await context.read<ChatProvider>().sendMessage(
            conversationId: widget.conversationId,
            mediaUrl: uploadResult['mediaUrl'],
            messageType: uploadResult['mediaType'] ?? 'image',
            replyToMessageId: _replyingTo?.id,
          );
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'envoi de l\'image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendVideo({ImageSource source = ImageSource.gallery}) async {
    final XFile? video = await _imagePicker.pickVideo(source: source);
    if (video == null) return;

    try {
      final uploadResult = await context.read<ChatProvider>().uploadFile(video.path);
      await context.read<ChatProvider>().sendMessage(
            conversationId: widget.conversationId,
            mediaUrl: uploadResult['mediaUrl'],
            messageType: 'video',
            replyToMessageId: _replyingTo?.id,
          );
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'envoi de la vidéo: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final uploadResult = await context.read<ChatProvider>().uploadFile(filePath);

      await context.read<ChatProvider>().sendMessage(
            conversationId: widget.conversationId,
            mediaUrl: uploadResult['mediaUrl'],
            messageType: 'document',
            replyToMessageId: _replyingTo?.id,
          );
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du document: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.spaceAround,
          children: [
            _buildAttachmentItem(
              icon: Icons.insert_drive_file,
              color: Colors.indigo,
              label: 'Document',
              onTap: () {
                Navigator.pop(context);
                _pickAndSendDocument();
              },
            ),
            _buildAttachmentItem(
              icon: Icons.camera_alt,
              color: Colors.pink,
              label: 'Caméra',
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(source: ImageSource.camera);
              },
            ),
            _buildAttachmentItem(
              icon: Icons.image,
              color: Colors.purple,
              label: 'Galerie',
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(source: ImageSource.gallery);
              },
            ),
            _buildAttachmentItem(
              icon: Icons.videocam,
              color: Colors.redAccent,
              label: 'Vidéo',
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showReactionPicker(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionPicker(
        onReactionSelected: (emoji) {
          context.read<ChatProvider>().addReaction(message.id, emoji);
        },
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    final currentUserId = context.read<ChatProvider>().currentUser?.id;
    final isMe = message.sender.id == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: Color(0xFF075E54)),
              title: const Text('Répondre'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingTo = message;
                  _editingMessage = null;
                });
              },
            ),
            if (isMe && message.isText)
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF075E54)),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = message;
                    _replyingTo = null;
                    _messageController.text = message.content ?? '';
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer pour moi'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().deleteMessage(message.id, false);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Supprimer pour tous'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ChatProvider>().deleteMessage(message.id, true);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _initiateCall(String callType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          conversationId: widget.conversationId,
          callType: callType,
          conversation: widget.conversation,
        ),
      ),
    );
  }

  void _showConversationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(widget.conversation?.displayName ?? 'Infos'),
              subtitle: Text(
                widget.conversation?.isGroup ?? false
                    ? '${widget.conversation?.participants.length ?? 0} participants'
                    : 'Discussion directe',
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: Text(widget.conversation?.isPinned ?? false
                  ? 'Désépingler'
                  : 'Épingler la discussion'),
              onTap: () {
                Navigator.pop(context);
                if (widget.conversation != null) {
                  context.read<ChatProvider>().pinConversation(
                        widget.conversationId,
                        !widget.conversation!.isPinned,
                      );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mettre en sourdine'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().muteConversation(widget.conversationId, null);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final isSomeoneTyping = chatProvider.typingUserId != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AvatarWidget(
              imageUrl: widget.conversation?.displayAvatar,
              name: widget.conversation?.displayName,
              size: 40,
              showOnlineStatus: true,
              isOnline: widget.conversation?.participants.any((p) => p.isOnline) ?? false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation?.displayName ?? 'Discussion',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    isSomeoneTyping
                        ? 'en train d\'écrire...'
                        : widget.conversation?.isGroup ?? false
                            ? 'Groupe'
                            : 'en ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSomeoneTyping ? const Color(0xFF25D366) : Colors.white70,
                      fontWeight: isSomeoneTyping ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () => _initiateCall('video'),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () => _initiateCall('audio'),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showConversationOptions,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.messages[widget.conversationId] ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun message pour le moment.\nDites bonjour ! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.sender.id == provider.currentUser?.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: MessageBubble(
                        message: message,
                        isMe: isMe,
                        onLongPress: () => _showMessageOptions(context, message),
                        onTap: () => _showReactionPicker(context, message),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Replying banner
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[300],
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    color: const Color(0xFF075E54),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réponse à ${_replyingTo!.sender.displayName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF075E54),
                          ),
                        ),
                        Text(
                          _replyingTo!.content ?? 'Média',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),

          // Editing banner
          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber[100],
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modification du message',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _editingMessage = null;
                        _messageController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input Bar & Emoji Picker
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Column(
              children: [
                if (_showEmojiPicker)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        _messageController.text += emoji.emoji;
                      },
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions),
                      onPressed: () {
                        setState(() => _showEmojiPicker = !_showEmojiPicker);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _showAttachmentOptions,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => _pickAndSendImage(source: ImageSource.camera),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && !_isTyping) {
                            setState(() => _isTyping = true);
                            context.read<ChatProvider>().sendTyping(widget.conversationId);
                          } else if (value.isEmpty && _isTyping) {
                            setState(() => _isTyping = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: const Color(0xFF075E54),
                      elevation: 2,
                      onPressed: _sendMessage,
                      child: Icon(
                        _editingMessage != null ? Icons.check : Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
