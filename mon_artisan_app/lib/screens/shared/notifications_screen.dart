import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../client/devis_detail_screen.dart';
import '../artisan/commande_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        final result = await FirestoreService.getNotifications(
          userId: authProvider.userModel!.id,
        );
        setState(() {
          _notifications = result['notifications'] as List<Map<String, dynamic>>;
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMore = result['hasMore'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await FirestoreService.getNotifications(
        userId: authProvider.userModel!.id,
        startAfter: _lastDocument,
      );
      
      final newNotifications = result['notifications'] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _notifications.addAll(newNotifications);
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMore = result['hasMore'] as bool;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirestoreService.markNotificationAsRead(notificationId);
      await _loadNotifications();
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

  @override
  Widget build(BuildContext context) {
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
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final role = authProvider.userModel?.role;
              if (role == 'client') {
                context.go(AppRouter.homeClient);
              } else {
                context.go(AppRouter.homeArtisan);
              }
            }
          },
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: () async {
                // Marquer toutes comme lues
                for (var notif in _notifications) {
                  if (notif['isRead'] == false) {
                    await FirestoreService.markNotificationAsRead(notif['id']);
                  }
                }
                await _loadNotifications();
              },
              child: Text(
                'Tout marquer lu',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Chargement...')
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppColors.greyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.greyDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vos notifications apparaîtront ici',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _notifications.length) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;
    final titre = notification['titre'] as String;
    final message = notification['message'] as String;
    final createdAt = (notification['createdAt'] as Timestamp).toDate();
    final notificationId = notification['id'] as String;

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          _markAsRead(notificationId);
        }
        
        final data = notification['data'] as Map<String, dynamic>?;
        final commandeId = data?['commandeId'] as String?;
        
        if (commandeId != null && context.mounted) {
          // Afficher un indicateur de chargement
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          
          try {
            final commande = await FirestoreService.getCommande(commandeId);
            
            if (!context.mounted) return;
            Navigator.pop(context); // Fermer le loader
            
            if (commande != null) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final isArtisan = authProvider.userModel?.role == 'artisan';
              
              if (isArtisan) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommandeDetailScreen(commande: commande),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DevisDetailScreen(commande: commande),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cette commande est introuvable.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } catch (e) {
            if (!context.mounted) return;
            Navigator.pop(context); // Fermer le loader
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors du chargement de la commande.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? AppColors.white : AppColors.primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? AppColors.greyLight : AppColors.primaryBlue.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(type),
                color: _getNotificationColor(type),
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titre,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.greyDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.greyMedium,
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

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'nouvelle_commande':
        return Icons.assignment_outlined;
      case 'commande_acceptee':
        return Icons.check_circle_outline;
      case 'commande_terminee':
        return Icons.done_all;
      case 'nouvel_avis':
        return Icons.star_outline;
      case 'paiement':
        return Icons.payment;
      case 'retrait':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'nouvelle_commande':
        return AppColors.primaryBlue;
      case 'commande_acceptee':
        return AppColors.success;
      case 'commande_terminee':
        return AppColors.success;
      case 'nouvel_avis':
        return AppColors.warning;
      case 'paiement':
        return AppColors.success;
      case 'retrait':
        return AppColors.primaryBlue;
      default:
        return AppColors.greyDark;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
