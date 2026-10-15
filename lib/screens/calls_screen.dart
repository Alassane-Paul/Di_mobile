import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/call.dart';
import '../models/user.dart';
import '../widgets/avatar_widget.dart';
import 'call_screen.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().getCallHistory();
    });
  }

  void _callUser(int conversationId, String callType, User targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          conversationId: conversationId,
          callType: callType,
          targetUser: targetUser,
        ),
      ),
    );
  }

  Future<void> _startNewCall(String callType) async {
    // Show user search dialog to pick a contact to call
    final chatProvider = context.read<ChatProvider>();
    final queryController = TextEditingController();
    List<User> results = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                callType == 'video' ? 'Nouvel appel vidéo' : 'Nouvel appel audio',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: queryController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher un contact...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onChanged: (val) async {
                  if (val.trim().isEmpty) {
                    setModalState(() => results = []);
                    return;
                  }
                  final res = await chatProvider.searchUsers(val.trim());
                  setModalState(() => results = res);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: results.isEmpty
                    ? const Center(child: Text('Recherchez un utilisateur pour appeler'))
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (ctx, i) {
                          final user = results[i];
                          return ListTile(
                            leading: AvatarWidget(
                              imageUrl: user.avatar,
                              name: user.displayName,
                              size: 40,
                            ),
                            title: Text(user.displayName),
                            subtitle: Text('@${user.username}'),
                            trailing: Icon(
                              callType == 'video' ? Icons.videocam : Icons.call,
                              color: const Color(0xFF25D366),
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              // Create direct conversation if not exists
                              final conv = await chatProvider.createConversation({
                                'type': 'direct',
                                'participantIds': [user.id],
                              });
                              if (mounted) {
                                _callUser(conv.id, callType, user);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.callHistory.isEmpty) {
          return Scaffold(
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_missed, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun appel récent', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showCallOptions(context),
              backgroundColor: const Color(0xFF25D366),
              child: const Icon(Icons.add_call),
            ),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => chatProvider.getCallHistory(),
            child: ListView.builder(
              itemCount: chatProvider.callHistory.length,
              itemBuilder: (context, index) {
                final call = chatProvider.callHistory[index];
                return _buildCallTile(call);
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCallOptions(context),
            backgroundColor: const Color(0xFF25D366),
            child: const Icon(Icons.add_call),
          ),
        );
      },
    );
  }

  Widget _buildCallTile(Call call) {
    return ListTile(
      leading: AvatarWidget(
        imageUrl: call.caller.avatar,
        name: call.caller.displayName,
        size: 50,
      ),
      title: Text(call.caller.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          Icon(
            call.isVideo ? Icons.videocam : Icons.call,
            size: 16,
            color: call.isMissed || call.isRejected ? Colors.red : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            _getCallStatusText(call),
            style: TextStyle(
              color: call.isMissed || call.isRejected ? Colors.red : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          if (call.duration != null) ...[
            const SizedBox(width: 8),
            Text(
              '• ${call.durationText}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          call.isVideo ? Icons.videocam : Icons.call,
          color: const Color(0xFF075E54),
        ),
        onPressed: () => _callUser(call.conversationId, call.type, call.caller),
      ),
      onTap: () => _callUser(call.conversationId, call.type, call.caller),
    );
  }

  String _getCallStatusText(Call call) {
    if (call.isMissed) return 'Appel manqué';
    if (call.isRejected) return 'Appel rejeté';
    if (call.isEnded) return 'Appel terminé';
    if (call.isConnected) return 'Appel connecté';
    return 'Appel';
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call, color: Color(0xFF075E54)),
              title: const Text('Nouvel appel audio'),
              onTap: () {
                Navigator.pop(context);
                _startNewCall('audio');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Color(0xFF075E54)),
              title: const Text('Nouvel appel vidéo'),
              onTap: () {
                Navigator.pop(context);
                _startNewCall('video');
              },
            ),
          ],
        ),
      ),
    );
  }
}
