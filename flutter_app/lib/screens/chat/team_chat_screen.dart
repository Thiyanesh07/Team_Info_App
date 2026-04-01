import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/services/chat_socket_service.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/providers/auth_provider.dart';
import 'package:team_info_app/screens/chat/widgets/chat_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:team_info_app/widgets/empty_states.dart';

class TeamChatScreen extends ConsumerStatefulWidget {
  const TeamChatScreen({super.key});
  @override
  ConsumerState<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends ConsumerState<TeamChatScreen> {
  final _api = ApiService();
  final _socket = ChatSocketService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<TeamMessage> _messages = [];
  bool _loading = true;
  final List<String> _typingUsers = [];
  
  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _reactionSub;

  @override
  void initState() {
    super.initState();
    _initialSetup();
  }

  Future<void> _initialSetup() async {
    final token = ref.read(authProvider).token;
    if (token != null) {
      _socket.connect(token);
    }

    _msgSub = _socket.messageStream.listen((msg) {
       if (msg is TeamMessage) {
         if (mounted) {
           setState(() => _messages.add(msg));
           _scrollToBottom();
         }
       }
    });

    _typingSub = _socket.typingStream.listen((data) {
       if (data['userId'] != ref.read(authProvider).user?.id && data['conversationId'] == null) {
         // This is a team typing event
         final userId = data['userId'];
         final isTyping = data['isTyping'] ?? false;
         if (mounted) {
           setState(() {
             if (isTyping && !_typingUsers.contains(userId)) {
               _typingUsers.add(userId);
             } else {
               _typingUsers.remove(userId);
             }
           });
         }
       }
    });

    _reactionSub = _socket.reactionStream.listen((data) {
       if (data['type'] == 'team') {
         final idx = _messages.indexWhere((m) => m.id == data['messageId']);
         if (idx != -1 && mounted) {
           setState(() {
             _messages[idx] = TeamMessage(
               id: _messages[idx].id,
               message: _messages[idx].message,
               imageUrl: _messages[idx].imageUrl,
               fileUrl: _messages[idx].fileUrl,
               fileName: _messages[idx].fileName,
               fileType: _messages[idx].fileType,
               replyToId: _messages[idx].replyToId,
               reactions: data['reactions'],
               isPinned: _messages[idx].isPinned,
               isRead: _messages[idx].isRead,
               isDelivered: _messages[idx].isDelivered,
               timestamp: _messages[idx].timestamp,
               sender: _messages[idx].sender,
             );
           });
         }
       }
    });

    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    final res = await _api.get(ApiConstants.teamChat);
    if (res.success && mounted) {
      setState(() {
        _messages = (res.data as List).map((e) => TeamMessage.fromJson(e)).toList();
        _loading = false;
      });
      _scrollToBottom();
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _socket.sendTeamMessage(text);
    _messageController.clear();
    _socket.setTypingTeam(false);
  }

  Future<void> _handleAttach() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.primary),
            title: const Text('Camera', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final x = await ImagePicker().pickImage(source: ImageSource.camera);
              if (x != null) _uploadMedia(x.path, 'IMAGE');
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo, color: AppColors.primary),
            title: const Text('Gallery', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final x = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (x != null) _uploadMedia(x.path, 'IMAGE');
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file, color: AppColors.primary),
            title: const Text('Document (PDF/Doc)', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              final res = await FilePicker.platform.pickFiles(type: FileType.any);
              if (res != null && res.files.single.path != null) {
                _uploadMedia(res.files.single.path!, 'DOCUMENT', name: res.files.single.name);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _uploadMedia(String path, String type, {String? name}) async {
    final res = await _api.uploadFile(ApiConstants.uploadFile, path);
    if (res.success && res.data != null) {
      _socket.sendTeamMessage(
        null, 
        imageUrl: type == 'IMAGE' ? res.data : null,
        fileUrl: type != 'IMAGE' ? res.data : null,
        fileType: type,
        fileName: name,
      );
    }
  }

  void _showReactionSheet(TeamMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['👍', '❤️', '😂', '🔥', '😮', '😢'].map((e) => GestureDetector(
            onTap: () {
              _socket.addReaction(msg.id, 'team', e);
              Navigator.pop(ctx);
            },
            child: Text(e, style: const TextStyle(fontSize: 32)),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team Chat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_typingUsers.isNotEmpty)
              Text('typing...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.push_pin_outlined), onPressed: _showPinnedMessages),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const EmptyMessages()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe = msg.senderId == user?.id; // In TeamMessage, we use senderId
                          return GestureDetector(
                            onLongPress: () => _showReactionSheet(msg),
                            child: PremiumMessageBubble(
                              message: msg,
                              isMe: isMe,
                              currentUserId: user?.id ?? '',
                            ),
                          );
                        },
                      ),
          ),
          GlassmorphicChatInput(
            controller: _messageController,
            onSend: _handleSend,
            onAttach: _handleAttach,
            onTyping: (v) => _socket.setTypingTeam(v),
            onVoiceSend: (path) => _uploadMedia(path, 'VOICE'),
          ),
        ],
      ),
    );
  }

  void _showPinnedMessages() async {
    final res = await _api.get(ApiConstants.teamChatPinned);
    if (!res.success || !mounted) return;

    final pinned = (res.data as List).map((e) => TeamMessage.fromJson(e)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📌 Pinned Messages', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            if (pinned.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('No pinned messages', style: GoogleFonts.inter(color: AppColors.textMuted)),
              ))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pinned.length,
                  itemBuilder: (ctx, i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(pinned[i].message ?? 'Image', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(pinned[i].sender?['name'] ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _reactionSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
