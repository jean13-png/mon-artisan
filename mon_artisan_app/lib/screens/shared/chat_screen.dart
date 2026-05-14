import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/firebase_service.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _chatId;
  bool _isLoading = true;
  String? _initError;
  int _limit = 20;
  bool _hasMore = true;
  bool _isNearTop = false;

  bool _isTyping = false;
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordFilePath;
  
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, bool> _isPlaying = {};
  final Map<String, Duration> _audioDurations = {};
  final Map<String, Duration> _audioPositions = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
    _initializeChat();
  }

  void _onScroll() {
    // Si on défile vers le haut (reverse: true, donc vers maxScrollExtent)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        setState(() {
          _limit += 20;
        });
      }
    }
  }

  Future<void> _initializeChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel!.id;
    final currentUserName = '${authProvider.userModel!.prenom} ${authProvider.userModel!.nom}';

    try {
      final chatId = await ChatService.getOrCreateChat(
        currentUserId: currentUserId,
        otherUserId: widget.otherUserId,
        currentUserName: currentUserName,
        otherUserName: widget.otherUserName,
      );

      setState(() {
        _chatId = chatId;
        _isLoading = false;
      });

      // Marquer les messages comme lus
      await ChatService.markMessagesAsRead(
        chatId: chatId,
        userId: currentUserId,
      );
    } catch (e) {
      print('[ERROR] Erreur initialisation chat: $e');
      setState(() {
        _isLoading = false;
        _initError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final dir = await getApplicationDocumentsDirectory();
        _recordFilePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordFilePath!,
        );
        
        setState(() {
          _isRecording = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission micro refusée. Veuillez l\'autoriser dans les paramètres.')),
          );
        }
      }
    } catch (e) {
      print('[ERROR] start recording: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      
      if (path != null && _chatId != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.userModel!.id;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Envoi du vocal en cours...'), duration: Duration(seconds: 2)),
          );
        }
        
        final file = File(path);
        final audioUrl = await FirebaseService.uploadAudioMessage(_chatId!, file);
        
        await ChatService.sendMessage(
          chatId: _chatId!,
          senderId: currentUserId,
          receiverId: widget.otherUserId,
          message: '🎵 Message vocal',
          type: 'audio',
          audioUrl: audioUrl,
        );
        
        _scrollToBottom();
      }
    } catch (e) {
      print('[ERROR] stop recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi du vocal')),
        );
      }
    }
  }

  // Filtre anti-contournement : détecte les numéros de téléphone et liens
  bool _containsForbiddenContent(String text) {
    // Regex pour détecter les numéros de téléphone (formats variés)
    final phonePatterns = [
      RegExp(r'\b\d{8,}\b'), // 8 chiffres ou plus consécutifs
      RegExp(r'\b\d{2}[\s\-\.]\d{2}[\s\-\.]\d{2}[\s\-\.]\d{2}\b'), // Format XX XX XX XX
      RegExp(r'\+?\d{1,4}[\s\-\.]?\(?\d{1,4}\)?[\s\-\.]?\d{1,4}[\s\-\.]?\d{1,9}'), // Format international
      RegExp(r'\b(whatsapp|telegram|viber|signal)\b', caseSensitive: false), // Apps de messagerie
    ];

    // Regex pour détecter les liens et URLs
    final linkPatterns = [
      RegExp(r'https?://[^\s]+', caseSensitive: false),
      RegExp(r'www\.[^\s]+', caseSensitive: false),
      RegExp(r'\b[a-zA-Z0-9\-]+\.(com|net|org|bj|fr)[^\s]*', caseSensitive: false),
    ];

    // Vérifier les numéros de téléphone
    for (var pattern in phonePatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    // Vérifier les liens
    for (var pattern in linkPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible d\'envoyer : conversation non initialisée.'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: AppColors.white,
            onPressed: _initializeChat,
          ),
        ),
      );
      return;
    }

    // Vérifier si le message contient du contenu interdit
    if (_containsForbiddenContent(text)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Contenu interdit',
                style: AppTextStyles.h3.copyWith(color: AppColors.error),
              ),
            ],
          ),
          content: Text(
            'Vous ne pouvez pas partager de numéros de téléphone, liens externes ou applications de messagerie.\n\nPour votre sécurité et celle de l\'artisan, toutes les communications doivent se faire via la messagerie Mon Artisan.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Compris',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel!.id;

    try {
      await ChatService.sendMessage(
        chatId: _chatId!,
        senderId: currentUserId,
        receiverId: widget.otherUserId,
        message: text,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Car reverse: true
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userModel!.id;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.greyLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.otherUserName,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        backgroundColor: AppColors.greyLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.otherUserName,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Impossible d\'ouvrir la conversation',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyMedium),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _initError = null;
                    });
                    _initializeChat();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message d'avertissement avec apparence douce
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              border: Border(
                left: BorderSide(
                  color: AppColors.warning,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Communication officielle',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Toutes les transactions et communications doivent se faire uniquement via Mon Artisan. Tout échange externe (WhatsApp, appel, SMS) dégage la plateforme de toute responsabilité en cas de litige.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.greyDark,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(_limit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.greyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.greyDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez la conversation',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.greyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                _hasMore = messages.length == _limit;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final message = messageDoc.data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == currentUserId;
                    final timestamp = (message['timestamp'] as Timestamp).toDate();

                    return _buildMessageBubble(
                      message,
                      isMe,
                      timestamp,
                      messageDoc.id,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_isRecording)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(
                            'Enregistrement...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Écrivez un message...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.greyMedium,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppColors.greyMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppColors.primaryBlue),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onLongPress: _isTyping ? null : _startRecording,
                    onLongPressUp: _isTyping ? null : _stopRecordingAndSend,
                    onTap: _isTyping ? _sendMessage : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isTyping ? Icons.send : Icons.mic,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe, DateTime timestamp, String messageId) {
    final type = messageData['type'] ?? 'text';
    final message = messageData['message'] ?? '';
    final audioUrl = messageData['audioUrl'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'audio' && audioUrl != null)
              _buildAudioPlayer(audioUrl, messageId, isMe)
            else
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isMe ? AppColors.white : AppColors.black,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.bodySmall.copyWith(
                color: isMe
                    ? AppColors.white.withOpacity(0.7)
                    : AppColors.greyMedium,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(String audioUrl, String messageId, bool isMe) {
    if (!_audioPlayers.containsKey(messageId)) {
      final player = AudioPlayer();
      _audioPlayers[messageId] = player;
      _isPlaying[messageId] = false;
      
      player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _audioDurations[messageId] = d);
      });
      player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _audioPositions[messageId] = p);
      });
      player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying[messageId] = false;
            _audioPositions[messageId] = Duration.zero;
          });
        }
      });
      
      player.setSourceUrl(audioUrl);
    }
    
    final isPlaying = _isPlaying[messageId] ?? false;
    final position = _audioPositions[messageId] ?? Duration.zero;
    final duration = _audioDurations[messageId] ?? Duration.zero;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final player = _audioPlayers[messageId]!;
            if (isPlaying) {
              await player.pause();
              setState(() => _isPlaying[messageId] = false);
            } else {
              // Pause all others
              for (var p in _audioPlayers.keys) {
                if (p != messageId && _isPlaying[p] == true) {
                  await _audioPlayers[p]!.pause();
                  setState(() => _isPlaying[p] = false);
                }
              }
              await player.resume();
              setState(() => _isPlaying[messageId] = true);
            }
          },
          child: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: isMe ? AppColors.white : AppColors.primaryBlue,
            size: 36,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 100,
              onChanged: (val) {
                final player = _audioPlayers[messageId]!;
                player.seek(Duration(milliseconds: val.toInt()));
              },
              activeColor: isMe ? AppColors.white : AppColors.primaryBlue,
              inactiveColor: isMe ? AppColors.white.withOpacity(0.3) : AppColors.greyLight,
            ),
          ),
        ),
      ],
    );
  }
}
