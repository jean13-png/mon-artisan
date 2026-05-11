import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/chat_service.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadConversations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreConversations();
    }
  }

  Future<void> _loadConversations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.id;

    if (currentUserId == null) {
      print('[ERROR] currentUserId est null');
      setState(() => _isLoading = false);
      return;
    }

    print('[INFO] ========================================');
    print('[INFO] Chargement des conversations pour: $currentUserId');
    setState(() => _isLoading = true);

    try {
      final result = await ChatService.getUserChats(userId: currentUserId);
      final conversations = result['conversations'] as List<Map<String, dynamic>>;
      
      print('[SUCCESS] ${conversations.length} conversation(s) trouvée(s)');
      print('[INFO] ========================================');

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMore = result['hasMore'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ERROR] Erreur chargement conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreConversations() async {
    if (_isLoadingMore || !_hasMore) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.id;
    if (currentUserId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await ChatService.getUserChats(
        userId: currentUserId,
        startAfter: _lastDocument,
      );
      
      final newConversations = result['conversations'] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _conversations.addAll(newConversations);
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMore = result['hasMore'] as bool;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('[ERROR] Erreur chargement plus de conversations: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Retour au dashboard approprié
              if (authProvider.userModel?.isArtisan == true) {
                context.go(AppRouter.homeArtisan);
              } else {
                context.go(AppRouter.homeClient);
              }
            }
          },
        ),
        title: Text(
          'Messagerie',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
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
                        'Aucune conversation',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.greyDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vos conversations apparaîtront ici',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _conversations.length) {
                        final conversation = _conversations[index];
                        return _buildConversationCard(conversation);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  ),
                ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final otherUserName = conversation['otherUserName'] as String;
    final lastMessage = conversation['lastMessage'] as String;
    final timestamp = conversation['timestamp'] as DateTime;
    final unreadCount = conversation['unreadCount'] as int;
    final chatId = conversation['chatId'] as String;
    final otherUserId = conversation['otherUserId'] as String;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        ).then((_) {
          // Recharger les conversations après retour du chat
          _loadConversations();
        });
      },
      onLongPress: () {
        _showDeleteDialog(chatId, otherUserName);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.isEmpty ? 'Aucun message' : lastMessage,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: unreadCount > 0
                          ? AppColors.black
                          : AppColors.greyDark,
                      fontWeight: unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Badge de messages non lus
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(String chatId, String otherUserName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Supprimer la conversation', style: AppTextStyles.h3),
          ],
        ),
        content: Text(
          'Voulez-vous supprimer la conversation avec $otherUserName ?\n\nCette action est irréversible.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.greyDark,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Supprimer',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteConversation(chatId);
    }
  }

  Future<void> _deleteConversation(String chatId) async {
    try {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Utiliser ChatService pour supprimer
      await ChatService.deleteChat(chatId);

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation supprimée'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Recharger la liste
      await _loadConversations();
    } catch (e) {
      print('[ERROR] Erreur suppression conversation: $e');
      
      // Fermer le loader
      if (mounted) Navigator.pop(context);
      
      // Afficher un message d'erreur
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
