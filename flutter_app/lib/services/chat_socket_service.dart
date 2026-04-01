import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/app_models.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  io.Socket? _socket;
  final _messageController = StreamController<dynamic>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionController = StreamController<Map<String, dynamic>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get reactionStream => _reactionController.stream;
  Stream<Map<String, dynamic>> get readStream => _readController.stream;

  void connect(String token) {
    if (_socket?.connected == true) return;

    String socketUrl = ApiConstants.socketUrl;

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('🚀 Chat Sockets Connected');
    });

    _socket!.on('personal-message', (data) {
      _messageController.add(ChatMessage.fromJson(data));
    });

    _socket!.on('team-message', (data) {
      _messageController.add(TeamMessage.fromJson(data));
    });

    _socket!.on('typing-personal', (data) => _typingController.add(data));
    _socket!.on('typing-team', (data) => _typingController.add(data));
    _socket!.on('reaction-updated', (data) => _reactionController.add(data));
    _socket!.on('messages-read', (data) => _readController.add(data));

    _socket!.onDisconnect((_) => debugPrint('🔌 Chat Sockets Disconnected'));
    _socket!.onConnectError((err) => debugPrint('❌ Socket Connection Error: $err'));
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join-conversation', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave-conversation', conversationId);
  }

  void sendPersonalMessage(String conversationId, String? text, {String? imageUrl, String? fileUrl, String? fileName, String? fileType, String? replyToId}) {
    _socket?.emit('personal-message', {
      'conversationId': conversationId,
      'message': text,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'replyToId': replyToId,
    });
  }

  void sendTeamMessage(String? text, {String? imageUrl, String? fileUrl, String? fileName, String? fileType, String? replyToId}) {
    _socket?.emit('team-message', {
      'message': text,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'replyToId': replyToId,
    });
  }

  void setTypingPersonal(String conversationId, bool isTyping) {
    _socket?.emit('typing-personal', {'conversationId': conversationId, 'isTyping': isTyping});
  }

  void setTypingTeam(bool isTyping) {
    _socket?.emit('typing-team', isTyping);
  }

  void addReaction(String messageId, String type, String emoji) {
    _socket?.emit('add-reaction', {
      'messageId': messageId,
      'type': type,
      'emoji': emoji,
    });
  }

  void markRead(String conversationId, String type) {
    _socket?.emit('mark-read', {'conversationId': conversationId, 'type': type});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
