import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';
import '../config/app_config.dart';

class SocketService {
  IO.Socket? _socket;

  // Callbacks
  Function(Message)? onNewMessage;
  Function(String)? onUserTyping;
  Function(String)? onUserOnline;
  Function(String)? onUserOffline;
  Function(Map<String, dynamic>)? onCallOffer;
  Function(Map<String, dynamic>)? onCallAnswer;
  Function(Map<String, dynamic>)? onIceCandidate;
  Function(Map<String, dynamic>)? onCallEnded;
  Function(Map<String, dynamic>)? onNewMediaDetected;

  bool get isConnected => _socket != null && _socket!.connected;

  Future<void> connect(String userId) async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      print('✅ Socket connecté');
      _socket!.emit('join', userId);
    });

    _socket!.on('new_message', (data) {
      if (onNewMessage != null) {
        onNewMessage!(Message.fromJson(data));
      }
    });

    _socket!.on('message_sent', (data) {
      if (onNewMessage != null) {
        onNewMessage!(Message.fromJson(data));
      }
    });

    _socket!.on('user_typing', (data) {
      if (onUserTyping != null) {
        onUserTyping!(data['userId']);
      }
    });

    _socket!.on('user_online', (data) {
      if (onUserOnline != null) {
        onUserOnline!(data['userId']);
      }
    });

    _socket!.on('user_offline', (data) {
      if (onUserOffline != null) {
        onUserOffline!(data['userId']);
      }
    });

    // WebRTC events
    _socket!.on('call_offer', (data) {
      if (onCallOffer != null) {
        onCallOffer!(data);
      }
    });

    _socket!.on('call_answer', (data) {
      if (onCallAnswer != null) {
        onCallAnswer!(data);
      }
    });

    _socket!.on('ice_candidate', (data) {
      if (onIceCandidate != null) {
        onIceCandidate!(data);
      }
    });

    _socket!.on('call_ended', (data) {
      if (onCallEnded != null) {
        onCallEnded!(data);
      }
    });

    // Surveillance event
    _socket!.on('new_media_detected', (data) {
      if (onNewMediaDetected != null) {
        onNewMediaDetected!(data);
      }
    });

    _socket!.on('disconnect', (_) {
      print('❌ Socket déconnecté');
    });

    _socket!.on('error', (error) {
      print('❌ Socket error: $error');
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_message', data);
    }
  }

  void typing(int conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing', {'conversationId': conversationId});
    }
  }

  void joinConversation(int conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_conversation', conversationId);
    }
  }

  void leaveConversation(int conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_conversation', conversationId);
    }
  }

  // WebRTC signaling
  void sendCallOffer(int callId, String offer, int receiverId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('call_offer', {
        'callId': callId,
        'offer': offer,
        'receiverId': receiverId,
      });
    }
  }

  void sendCallAnswer(int callId, String answer, int callerId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('call_answer', {
        'callId': callId,
        'answer': answer,
        'callerId': callerId,
      });
    }
  }

  void sendIceCandidate(int callId, String candidate, int targetUserId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('ice_candidate', {
        'callId': callId,
        'candidate': candidate,
        'targetUserId': targetUserId,
      });
    }
  }

  void endCall(int callId, int receiverId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('end_call', {
        'callId': callId,
        'receiverId': receiverId,
      });
    }
  }

  void toggleSurveillance(bool enabled) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('surveillance_toggle', {'enabled': enabled});
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
