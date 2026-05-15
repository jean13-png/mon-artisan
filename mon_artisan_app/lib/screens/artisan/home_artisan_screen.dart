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
      if (authProvider.userModel != null && authProvider.userModel!.isArtisan) {
        _loadArtisanData();
        _checkLocationPermission();
        _loadUnreadCounts();
        _startAutoRefresh();
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

    int notifCount = 0;
    int msgCount = 0;

    try {
      try {
        final snap = await FirebaseService.firestore
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .get();
        notifCount = snap.docs.length;
      } catch (_) {}

      try {
        msgCount = await ChatService.getUnreadMessagesCount(currentUserId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = notifCount;
          _unreadMessagesCount = msgCount;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool('artisan_has_asked_location_permission') ?? false;
    if (!hasAsked && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await LocationPermissionDialog.show(context);
        await prefs.setBool('artisan_has_asked_location_permission', true);
        if (mounted) setState(() {});
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

    if (user == null || artisan == null) {
      return const LoadingWidget(message: 'Chargement de votre profil...');
    }

    final nouvellesCommandes = commandeProvider.commandes
        .where((c) => c.statut == 'en_attente' || c.statut == 'diagnostic_paye')
        .toList();

    return DoubleTapToExit(
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: _buildAppBar(context, authProvider, user),
        body: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            await artisanProvider.loadArtisanProfile(user.id);
            await commandeProvider.loadArtisanCommandes(user.id);
            await _loadUnreadCounts();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context, artisanProvider, user, artisan),
                const SizedBox(height: 20),
                _buildAlerts(context, artisan),
                _buildRevenusCard(context, artisan),
                const SizedBox(height: 20),
                _buildStatsRow(artisan),
                const SizedBox(height: 24),
                _buildCommandesSection(context, nouvellesCommandes),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthProvider authProvider, dynamic user) {
    return AppBar(
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      titleSpacing: 20,
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Mon ',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.accentRed,
                letterSpacing: 0.3,
              ),
            ),
            TextSpan(
              text: 'Artisan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: AppColors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        BadgeIcon(
          icon: Icons.chat_bubble_outline,
          count: _unreadMessagesCount,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConversationsListScreen()),
            ).then((_) => _loadUnreadCounts());
          },
        ),
        BadgeIcon(
          icon: Icons.notifications_outlined,
          count: _unreadNotificationsCount,
          onPressed: () => context.push(AppRouter.notifications),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: AppColors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                context.push(AppRouter.editProfile);
                break;
              case 'revenus':
                context.push(AppRouter.revenus);
                break;
              case 'switch_client':
                context.go(AppRouter.homeClient);
                break;
              case 'settings':
                context.push(AppRouter.settings);
                break;
              case 'logout':
                authProvider.signOut();
                context.go(AppRouter.roleSelection);
                break;
            }
          },
          itemBuilder: (context) => [
            _menuItem('profile', Icons.person_outline, 'Mon profil', AppColors.primaryBlue),
            _menuItem('revenus', Icons.account_balance_wallet_outlined, 'Mes revenus', AppColors.success),
            if (user.isClient)
              _menuItem('switch_client', Icons.swap_horiz, 'Mode Client', AppColors.primaryBlue),
            _menuItem('settings', Icons.settings_outlined, 'Paramètres', AppColors.greyDark),
            _menuItem('logout', Icons.logout, 'Déconnexion', AppColors.error),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: value == 'logout' ? AppColors.error : AppColors.onSurface,
              )),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, ArtisanProvider artisanProvider, dynamic user, dynamic artisan) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.person, color: AppColors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour,',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white.withOpacity(0.8))),
                      Text(
                        '${user.prenom} ${user.nom}',
                        style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 20),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(artisan.metier,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Statut disponibilité
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: artisan.disponibilite ? AppColors.success : AppColors.greyMedium,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    artisan.disponibilite ? 'Disponible' : 'Non disponible',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: artisan.disponibilite,
                      onChanged: (v) => artisanProvider.updateDisponibilite(v),
                      activeColor: AppColors.success,
                      inactiveThumbColor: AppColors.greyMedium,
                      activeTrackColor: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            if (!artisan.estRealementDisponible && artisan.commandeEnCours != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text('En mission — invisible dans les recherches',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts(BuildContext context, dynamic artisan) {
    if (artisan.isProfileComplete && artisan.isVerified) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: !artisan.isProfileComplete
          ? _alertBanner(
              context,
              icon: Icons.info_outline,
              color: AppColors.warning,
              title: 'Profil incomplet',
              body:
                  'Complétez votre profil (diplôme, CIP, photos) dans les 7 jours pour éviter la suspension.',
              actionLabel: 'Compléter maintenant',
              onAction: () => context.push(AppRouter.completeProfile),
            )
          : _alertBanner(
              context,
              icon: Icons.pending_outlined,
              color: AppColors.primaryBlue,
              title: 'Vérification en cours',
              body: 'Votre profil est en cours de vérification par notre équipe.',
            ),
    );
  }

  Widget _alertBanner(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 4),
                    Text(body,
                        style:
                            AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(actionLabel, style: AppTextStyles.button.copyWith(fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenusCard(BuildContext context, dynamic artisan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3C6E), Color(0xFF2563A8)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenus disponibles',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.white.withOpacity(0.75))),
                  const SizedBox(height: 6),
                  Text(
                    '${artisan.revenusDisponibles.toStringAsFixed(0)} FCFA',
                    style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total : ${artisan.revenusTotal.toStringAsFixed(0)} FCFA',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.white.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: artisan.revenusDisponibles > 0
                  ? () => context.push(AppRouter.revenus)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.white.withOpacity(0.3),
                foregroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              child: Text('Retirer',
                  style: AppTextStyles.button.copyWith(
                      color: artisan.revenusDisponibles > 0
                          ? AppColors.primaryBlue
                          : AppColors.white.withOpacity(0.5),
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(dynamic artisan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistiques', style: AppTextStyles.h3.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  label: 'Commandes',
                  value: '${artisan.nombreCommandes}',
                  icon: Icons.assignment_outlined,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  label: 'Note',
                  value: artisan.noteGlobale.toStringAsFixed(1),
                  icon: Icons.star_outline_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  label: 'Revenus (K)',
                  value: '${(artisan.revenusTotal / 1000).toStringAsFixed(0)}K',
                  icon: Icons.monetization_on_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.h2.copyWith(color: AppColors.onSurface, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.greyDark, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCommandesSection(BuildContext context, List<dynamic> commandes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nouvelles demandes (${commandes.length})',
                  style: AppTextStyles.h3.copyWith(fontSize: 16)),
              TextButton(
                onPressed: () =>
                    context.push('${AppRouter.commandesHistory}?role=artisan'),
                child: Text('Voir tout',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (commandes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 44, color: AppColors.greyMedium),
                  const SizedBox(height: 12),
                  Text('Aucune nouvelle demande',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.greyDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Les nouvelles commandes apparaîtront ici',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyMedium),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...commandes.take(5).map((c) => _commandeCard(context, c)),
        ],
      ),
    );
  }

  Widget _commandeCard(BuildContext context, dynamic commande) {
    final isDiag = commande.typeCommande == 'diagnostic_requis';
    final isPaye = commande.statut == 'diagnostic_paye';

    return GestureDetector(
      onTap: () => context.push(AppRouter.commandeDetail, extra: commande),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Barre colorée supérieure
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: isDiag ? AppColors.primaryBlue : AppColors.warning,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          commande.description,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDiag ? AppColors.primaryBlue : AppColors.warning)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDiag ? 'DIAGNOSTIC' : 'DEVIS',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDiag ? AppColors.primaryBlue : AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 15, color: AppColors.greyDark),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${commande.ville} — ${commande.quartier}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.greyDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.payments_outlined, size: 15, color: AppColors.greyDark),
                      const SizedBox(width: 4),
                      Text(
                        isDiag
                            ? 'Diagnostic : ${commande.montantDiagnostic?.toStringAsFixed(0) ?? '---'} FCFA'
                            : '${commande.montant.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.greyDark),
                      ),
                      if (isPaye) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('PAYE',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Voir les détails',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.primaryBlue),
                    ],
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
