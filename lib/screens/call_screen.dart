import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar_widget.dart';

class CallScreen extends StatefulWidget {
  final int conversationId;
  final String callType; // 'audio' or 'video'
  final User? targetUser;
  final Conversation? conversation;
  final bool isIncoming;
  final int? callId;

  const CallScreen({
    super.key,
    required this.conversationId,
    required this.callType,
    this.targetUser,
    this.conversation,
    this.isIncoming = false,
    this.callId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isVideoOff = false;
  bool _isConnected = false;
  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  int? _activeCallId;

  @override
  void initState() {
    super.initState();
    _activeCallId = widget.callId;
    if (!widget.isIncoming && _activeCallId == null) {
      _startCall();
    } else if (widget.isIncoming) {
      // Incoming call waiting for answer
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCall() async {
    try {
      final call = await context.read<ChatProvider>().initiateCall(
        widget.conversationId,
        widget.callType,
      );
      if (mounted) {
        setState(() => _activeCallId = call.id);
        // Simulate remote ringing then connection after 2s for immediate demo
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _onCallConnected();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'initier l\'appel: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _onCallConnected() {
    setState(() => _isConnected = true);
    if (_activeCallId != null) {
      context.read<ChatProvider>().updateCallStatus(_activeCallId!, 'connected');
    }
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  Future<void> _endCall() async {
    _durationTimer?.cancel();
    if (_activeCallId != null) {
      await context.read<ChatProvider>().updateCallStatus(_activeCallId!, 'ended');
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.targetUser?.displayName ??
        widget.conversation?.displayName ??
        'Appel Di';
    final avatarUrl = widget.targetUser?.avatar ?? widget.conversation?.displayAvatar;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B21),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Header: User Info
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected
                  ? _formatDuration(_callDurationSeconds)
                  : widget.isIncoming
                      ? 'Appel entrant (${widget.callType == 'video' ? 'Vidéo' : 'Audio'})...'
                      : 'Sonnerie...',
              style: TextStyle(
                color: _isConnected ? const Color(0xFF25D366) : Colors.white70,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            // Avatar
            Center(
              child: AvatarWidget(
                imageUrl: avatarUrl,
                name: displayName,
                size: 130,
              ),
            ),
            const Spacer(),
            // Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2C34),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  IconButton(
                    iconSize: 32,
                    color: _isMuted ? Colors.redAccent : Colors.white,
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                    },
                  ),
                  // Video Toggle (if video call)
                  if (widget.callType == 'video')
                    IconButton(
                      iconSize: 32,
                      color: _isVideoOff ? Colors.redAccent : Colors.white,
                      icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
                      onPressed: () {
                        setState(() => _isVideoOff = !_isVideoOff);
                      },
                    ),
                  // Speaker Button
                  IconButton(
                    iconSize: 32,
                    color: _isSpeaker ? const Color(0xFF25D366) : Colors.white,
                    icon: Icon(_isSpeaker ? Icons.volume_up : Icons.volume_down),
                    onPressed: () {
                      setState(() => _isSpeaker = !_isSpeaker);
                    },
                  ),
                  // End Call Button
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
