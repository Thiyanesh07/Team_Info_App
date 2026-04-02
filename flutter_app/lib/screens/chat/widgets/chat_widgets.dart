import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_info_app/core/theme/app_theme.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:any_link_preview/any_link_preview.dart';

class PremiumMessageBubble extends StatefulWidget {
  final dynamic message;
  final bool isMe;
  final String currentUserId;

  const PremiumMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
  });

  @override
  State<PremiumMessageBubble> createState() => _PremiumMessageBubbleState();
}

class _PremiumMessageBubbleState extends State<PremiumMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  bool _isLink(String text) {
    return AnyLinkPreview.isValidLink(text);
  }

  @override
  Widget build(BuildContext context) {
    final senderName = widget.message.sender?['name'] ?? 'Unknown';
    final hasFile = widget.message.fileUrl != null;
    final isVoice = widget.message.fileType == 'VOICE';
    final msgText = widget.message.message ?? '';
    final hasLink = _isLink(msgText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: widget.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!widget.isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                senderName,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  gradient: widget.isMe ? AppColors.primaryGradient : null,
                  color: widget.isMe
                      ? null
                      : AppColors.surfaceLight.withAlpha(180),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                    bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          widget.message.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),

                    if (hasFile &&
                        !isVoice &&
                        widget.message.fileType != 'IMAGE')
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.message.fileName ?? 'File',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (isVoice)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                              ),
                              color: widget.isMe
                                  ? Colors.white
                                  : AppColors.primary,
                              onPressed: () {
                                if (_isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.play(
                                    UrlSource(widget.message.fileUrl!),
                                  );
                                }
                              },
                            ),
                            Expanded(
                              child: Slider(
                                value: _position.inMilliseconds.toDouble(),
                                max: _duration.inMilliseconds.toDouble() > 0
                                    ? _duration.inMilliseconds.toDouble()
                                    : 1.0,
                                activeColor: widget.isMe
                                    ? Colors.white
                                    : AppColors.primary,
                                inactiveColor: widget.isMe
                                    ? Colors.white24
                                    : Colors.grey[300],
                                onChanged: (v) {
                                  _audioPlayer.seek(
                                    Duration(milliseconds: v.toInt()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (msgText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msgText,
                              style: GoogleFonts.inter(
                                color: widget.isMe
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            if (hasLink)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: AnyLinkPreview(
                                  link: msgText,
                                  displayDirection:
                                      UIDirection.uiDirectionVertical,
                                  showMultimedia: true,
                                  bodyMaxLines: 3,
                                  bodyTextOverflow: TextOverflow.ellipsis,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  bodyStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  placeholderWidget: const SizedBox.shrink(),
                                  errorWidget: const SizedBox.shrink(),
                                  backgroundColor: Colors.black.withAlpha(20),
                                  borderRadius: 12,
                                ),
                              ),
                          ],
                        ),
                      ),

                    if (widget.message.reactions != null &&
                        (widget.message.reactions as Map).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Wrap(
                          spacing: 4,
                          children: (widget.message.reactions as Map).entries
                              .map((e) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(40),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${e.key} ${(e.value as List).length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                  ],
                ),
              )
              .animate()
              .fade(duration: 300.ms)
              .slideX(
                begin: widget.isMe ? 0.2 : -0.2,
                end: 0,
                curve: Curves.easeOutCubic,
              ),

          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(widget.message.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    widget.message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: widget.message.isRead
                        ? Colors.blue
                        : AppColors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class GlassmorphicChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final Function(bool) onTyping;
  final Function(String) onVoiceSend;

  const GlassmorphicChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onTyping,
    required this.onVoiceSend,
  });

  @override
  State<GlassmorphicChatInput> createState() => _GlassmorphicChatInputState();
}

class _GlassmorphicChatInputState extends State<GlassmorphicChatInput> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasTypedMessage = false;

  void _syncTypedState() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next != _hasTypedMessage && mounted) {
      setState(() => _hasTypedMessage = next);
    }
  }

  @override
  void initState() {
    super.initState();
    _hasTypedMessage = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_syncTypedState);
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      widget.onVoiceSend(path);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTypedState);
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(color: AppColors.background.withAlpha(150)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(50),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Row(
              children: [
                if (!_isRecording)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: widget.onAttach,
                  ),
                Expanded(
                  child: _isRecording
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.mic, color: Colors.red, size: 16)
                                  .animate(onPlay: (c) => c.repeat())
                                  .fade(duration: 500.ms),
                              const SizedBox(width: 8),
                              const Text(
                                'Recording...',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  await _recorder.stop();
                                  setState(() => _isRecording = false);
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextField(
                          controller: widget.controller,
                          onChanged: (v) =>
                              widget.onTyping(v.trim().isNotEmpty),
                          onSubmitted: (_) {
                            if (_hasTypedMessage) {
                              widget.onSend();
                            }
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withAlpha(100),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                ),
                GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isRecording
                            ? Icons.mic
                            : (_hasTypedMessage
                                  ? Icons.send_rounded
                                  : Icons.mic_none),
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _hasTypedMessage ? widget.onSend : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
