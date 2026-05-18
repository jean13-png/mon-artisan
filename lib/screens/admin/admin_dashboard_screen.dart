import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/double_tap_to_exit.dart';
import 'admin_reports_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_withdrawals_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalArtisans = 0;
  int _artisansEnAttente = 0;
  int _totalClients = 0;
  int _totalCommandes = 0;
  int _signalementsEnAttente = 0;
  int _agentsEnAttente = 0;
  int _retraitsEnAttente = 0;
  double _revenusTotal = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Compter les artisans (Utilisation de count() pour la performance)
      final artisansCount = await FirebaseService.firestore
          .collection('artisans')
          .count()
          .get();
      _totalArtisans = artisansCount.count ?? 0;

      // Compter les artisans en attente de validation
      final artisansEnAttenteCount1 = await FirebaseService.firestore
          .collection('artisans')
          .where('verificationStatus', isEqualTo: 'pending')
          .count()
          .get();
      
      final artisansEnAttenteCount2 = await FirebaseService.firestore
          .collection('artisans')
          .where('isProfileComplete', isEqualTo: true)
          .where('isVerified', isEqualTo: false)
          .count()
          .get();
      
      // Approximation (Firestore count n'accepte pas encore OR facilement en client-side sans index complexe)
      _artisansEnAttente = (artisansEnAttenteCount1.count ?? 0) + (artisansEnAttenteCount2.count ?? 0);

      // Compter les clients
      final clientsCount = await FirebaseService.firestore
          .collection('users')
          .where('roles', arrayContains: 'client')
          .count()
          .get();
      _totalClients = clientsCount.count ?? 0;

      // Compter les commandes
      final commandesCount = await FirebaseService.firestore
          .collection('commandes')
          .count()
          .get();
      _totalCommandes = commandesCount.count ?? 0;

      // Calculer les revenus totaux (Ici on doit garder le fetch car on fait une somme, 
      // mais on limite aux commandes payées pour plus de précision)
      final revenusSnapshot = await FirebaseService.firestore
          .collection('commandes')
          .where('paiementStatut', isEqualTo: 'paye')
          .get();
      
      double revenus = 0.0;
      for (var doc in revenusSnapshot.docs) {
        revenus += (doc.data()['commission'] ?? 0.0).toDouble();
      }
      _revenusTotal = revenus;

      // Compter les signalements en attente
      final signalementsCount = await FirebaseService.firestore
          .collection('signalements')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      _signalementsEnAttente = signalementsCount.count ?? 0;

      // Compter les agents en attente
      final agentsCount = await FirebaseService.firestore
          .collection('users')
          .where('agentStatus', isEqualTo: 'pending')
          .count()
          .get();
      _agentsEnAttente = agentsCount.count ?? 0;

      // Compter les retraits en attente
      final retraitsCount = await FirebaseService.firestore
          .collection('retraits')
          .where('statut', isEqualTo: 'en_attente')
          .count()
          .get();
      _retraitsEnAttente = retraitsCount.count ?? 0;

      setState(() => _isLoading = false);
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion', style: AppTextStyles.h3),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Déconnexion',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      if (mounted) {
        context.go(AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoubleTapToExit(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administration',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Tableau de bord centralisé',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.white),
              onPressed: _loadStatistics,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStatistics,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Carte des Revenus (Header)
                      _buildMainStatsCard(),

                      const SizedBox(height: 28),

                      // Grille de statistiques
                      Text(
                        'Indicateurs clés',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildStatCard(
                            'Artisans',
                            _totalArtisans.toString(),
                            Icons.construction_rounded,
                            const Color(0xFF3B82F6), // Bleu moderne
                            'Total inscrits',
                          ),
                          _buildStatCard(
                            'En attente',
                            _artisansEnAttente.toString(),
                            Icons.hourglass_bottom_rounded,
                            const Color(0xFFF59E0B), // Ambre moderne
                            'À valider',
                          ),
                          _buildStatCard(
                            'Clients',
                            _totalClients.toString(),
                            Icons.people_alt_rounded,
                            const Color(0xFF10B981), // Emeraude moderne
                            'Utilisateurs',
                          ),
                          _buildStatCard(
                            'Commandes',
                            _totalCommandes.toString(),
                            Icons.receipt_long_rounded,
                            const Color(0xFFEF4444), // Rouge moderne
                            'Activité totale',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Actions rapides
                      Text(
                        'Gestion & Opérations',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildActionGrid(),

                      const SizedBox(height: 40),

                      // Bouton de déconnexion
                      TextButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.error),
                        label: Text(
                          'Déconnexion sécurisée',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.error.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMainStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chiffre d\'affaires total',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up,
                    color: AppColors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_revenusTotal.toStringAsFixed(0)} FCFA',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: AppColors.white, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Commissions nettes générées',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.greyDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildActionCard(
          'Artisans',
          Icons.how_to_reg_rounded,
          const Color(0xFF10B981),
          () => context.go('/admin/validate-artisans'),
          badge: _artisansEnAttente > 0 ? _artisansEnAttente.toString() : null,
        ),
        _buildActionCard(
          'Agents',
          Icons.badge_rounded,
          AppColors.primaryBlue,
          () => context.go('/admin/manage-agents'),
          badge: _agentsEnAttente > 0 ? _agentsEnAttente.toString() : null,
        ),
        _buildActionCard(
          'Utilisateurs',
          Icons.manage_accounts_rounded,
          const Color(0xFF6366F1),
          () => context.go('/admin/manage-users'),
        ),
        _buildActionCard(
          'Signalements',
          Icons.gavel_rounded,
          const Color(0xFFF59E0B),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
            );
          },
          badge:
              _signalementsEnAttente > 0 ? _signalementsEnAttente.toString() : null,
        ),
        _buildActionCard(
          'Paiements',
          Icons.account_balance_rounded,
          const Color(0xFFEF4444),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminTransactionsScreen()),
            );
          },
        ),
        _buildActionCard(
          'Retraits',
          Icons.payments_rounded,
          const Color(0xFF8B5CF6),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminWithdrawalsScreen()),
            );
          },
          badge: _retraitsEnAttente > 0 ? _retraitsEnAttente.toString() : null,
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap,
      {String? badge}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (badge != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

