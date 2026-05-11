import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/double_tap_to_exit.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/location_permission_dialog.dart';
import '../../widgets/badge_icon.dart';
import '../shared/conversations_list_screen.dart';

class HomeArtisanScreen extends StatefulWidget {
  const HomeArtisanScreen({super.key});

  @override
  State<HomeArtisanScreen> createState() => _HomeArtisanScreenState();
}

class _HomeArtisanScreenState extends State<HomeArtisanScreen> {
  int _unreadNotificationsCount = 0;
  int _unreadMessagesCount = 0;
  bool _autoRefreshActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        if (authProvider.userModel!.isArtisan) {
          _loadArtisanData();
          _checkLocationPermission();
          _loadUnreadCounts();
          _startAutoRefresh();
        }
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshActive = false;
    super.dispose();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (!_autoRefreshActive || !mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        _loadArtisanData();
        _loadUnreadCounts();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadUnreadCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.id;
    
    if (currentUserId == null) return;

    // Initialiser à 0 par défaut
    int notifCount = 0;
    int msgCount = 0;

    try {
      // Compter les notifications non lues
      try {
        final notificationsSnapshot = await FirebaseService.firestore
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .get();
        notifCount = notificationsSnapshot.docs.length;
      } catch (e) {
        print('[ERROR] Erreur comptage notifications: $e');
      }

      // Compter les messages non lus avec ChatService
      try {
        msgCount = await ChatService.getUnreadMessagesCount(currentUserId);
      } catch (e) {
        print('[ERROR] Erreur comptage messages: $e');
      }

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = notifCount;
          _unreadMessagesCount = msgCount;
        });
      }
    } catch (e) {
      print('[ERROR] Erreur chargement compteurs: $e');
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = 0;
          _unreadMessagesCount = 0;
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    // Vérifier si on a déjà demandé la permission
    final prefs = await SharedPreferences.getInstance();
    final hasAskedPermission = prefs.getBool('artisan_has_asked_location_permission') ?? false;
    
    if (!hasAskedPermission && mounted) {
      // Attendre 2 secondes pour que l'UI soit chargée
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        final granted = await LocationPermissionDialog.show(context);
        await prefs.setBool('artisan_has_asked_location_permission', true);
        
        if (granted) {
          // Permission accordée
          setState(() {});
        }
      }
    }
  }

  Future<void> _loadArtisanData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
    
    await artisanProvider.loadArtisanProfile(authProvider.userModel!.id);
    if (!mounted) return;

    if (artisanProvider.currentArtisan != null) {
      Provider.of<CommandeProvider>(context, listen: false)
          .loadArtisanCommandes(authProvider.userModel!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final artisanProvider = Provider.of<ArtisanProvider>(context);
    final commandeProvider = Provider.of<CommandeProvider>(context);
    final user = authProvider.userModel;
    final artisan = artisanProvider.currentArtisan;
    
    // Filtrer les nouvelles commandes (en_attente)
    final nouvellesCommandes = commandeProvider.commandes
        .where((c) => c.statut == 'en_attente')
        .toList();

    if (user == null || artisan == null) {
      return const LoadingWidget(message: 'Chargement de votre profil...');
    }

    return DoubleTapToExit(
      child: Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.accentRed,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_mon_artisan.png',
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Mon Artisan',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.white,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          BadgeIcon(
            icon: Icons.chat_bubble_outline,
            count: _unreadMessagesCount,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationsListScreen(),
                ),
              ).then((_) => _loadUnreadCounts());
            },
          ),
          BadgeIcon(
            icon: Icons.notifications_outlined,
            count: _unreadNotificationsCount,
            onPressed: () {
              context.push(AppRouter.notifications);
            },
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: AppColors.white),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push(AppRouter.editProfile);
                  break;
                case 'revenus':
                  context.push(AppRouter.revenus);
                  break;
                case 'switch_client':
                  context.go(AppRouter.homeClient); // Garder go() pour switch de rôle
                  break;
                case 'settings':
                  context.push(AppRouter.settings);
                  break;
                case 'logout':
                  authProvider.signOut();
                  context.go(AppRouter.roleSelection); // Garder go() pour logout
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'revenus',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet),
                    SizedBox(width: 8),
                    Text('Mes revenus'),
                  ],
                ),
              ),
              if (user.isClient)
                const PopupMenuItem(
                  value: 'switch_client',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz),
                      SizedBox(width: 8),
                      Text('Passer en mode Client'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await artisanProvider.loadArtisanProfile(user.id);
          await commandeProvider.loadArtisanCommandes(user.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec salutation et statut
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${user.prenom} !',
                      style: AppTextStyles.h2.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artisan.metier,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 24),
                    
                    // Statut en ligne/hors ligne
                    Row(
                      children: [
                        Text(
                          'Statut : ',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: artisan.disponibilite ? AppColors.success : AppColors.greyMedium,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          artisan.disponibilite ? 'En ligne' : 'Hors ligne',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: artisan.disponibilite,
                          onChanged: (value) {
                            artisanProvider.updateDisponibilite(value);
                          },
                          activeThumbColor: AppColors.success,
                          inactiveThumbColor: AppColors.greyMedium,
                        ),
                      ],
                    ),
                    
                    // Badge "En mission" si commande en cours
                    if (!artisan.estRealementDisponible && artisan.commandeEnCours != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.work, size: 18, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Text(
                                'En mission - Invisible dans les recherches',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Message pour profil incomplet (7 jours de grâce)
              if (!artisan.isProfileComplete)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profil incomplet',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vous avez 7 jours pour compléter votre profil (diplôme, CIP, photos). Après ce délai, votre compte sera suspendu.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.greyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push(AppRouter.completeProfile);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Compléter mon profil maintenant'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (!artisan.isProfileComplete)
                const SizedBox(height: 24),
              
              // Message de vérification en attente
              if (artisan.isProfileComplete && !artisan.isVerified)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending_outlined, color: AppColors.warning, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profil en cours de vérification',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Votre profil est en cours de vérification par notre équipe. Vous serez notifié une fois validé.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.greyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (artisan.isProfileComplete && !artisan.isVerified)
                const SizedBox(height: 24),
              
              // Revenus disponibles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Revenus disponibles',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${artisan.revenusDisponibles.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.success,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: artisan.revenusDisponibles > 0 
                              ? () {
                                  context.push(AppRouter.revenus);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Retirer',
                            style: AppTextStyles.button,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Statistiques du mois
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiques du mois',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '${artisan.nombreCommandes}',
                            'Commandes',
                            Icons.assignment,
                            AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            artisan.noteGlobale.toStringAsFixed(1),
                            'Note',
                            Icons.star,
                            AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '${(artisan.revenusTotal / 1000).toStringAsFixed(0)}K',
                            'FCFA',
                            Icons.monetization_on,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Nouvelles commandes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nouvelles commandes (${nouvellesCommandes.length})',
                          style: AppTextStyles.h3,
                        ),
                        TextButton(
                          onPressed: () {
                            context.push(AppRouter.commandesHistory);
                          },
                          child: Text(
                            'Voir tout',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.accentRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (nouvellesCommandes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: AppColors.greyMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune nouvelle commande',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.greyDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Les nouvelles commandes apparaîtront ici',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.greyMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...nouvellesCommandes
                          .take(3)
                          .map((commande) => _buildCommandeCard(context, commande)),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ), // Fermeture du Scaffold
    ); // Fermeture du DoubleTapToExit
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.greyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandeCard(BuildContext context, dynamic commande) {
    return GestureDetector(
      onTap: () {
        context.push(AppRouter.commandeDetail, extra: commande);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commande.description,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Nouveau',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.greyDark,
                ),
                const SizedBox(width: 4),
                Text(
                  '${commande.ville} - ${commande.quartier}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.greyDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  size: 16,
                  color: AppColors.greyDark,
                ),
                const SizedBox(width: 4),
                Text(
                  '${commande.montant.toStringAsFixed(0)} FCFA',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.greyDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Appuyez pour voir les détails',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.accentRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
