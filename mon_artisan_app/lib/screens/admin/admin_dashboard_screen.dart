import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';

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
      // Compter les artisans
      final artisansSnapshot = await FirebaseService.firestore
          .collection('artisans')
          .get();
      _totalArtisans = artisansSnapshot.docs.length;

      // Compter les artisans en attente de validation
      final artisansEnAttenteSnapshot = await FirebaseService.firestore
          .collection('artisans')
          .where('verificationStatus', isEqualTo: 'pending')
          .get();
      _artisansEnAttente = artisansEnAttenteSnapshot.docs.length;

      // Compter les clients
      final clientsSnapshot = await FirebaseService.firestore
          .collection('users')
          .where('roles', arrayContains: 'client')
          .get();
      _totalClients = clientsSnapshot.docs.length;

      // Compter les commandes
      final commandesSnapshot = await FirebaseService.firestore
          .collection('commandes')
          .get();
      _totalCommandes = commandesSnapshot.docs.length;

      // Calculer les revenus totaux (commissions)
      double revenus = 0.0;
      for (var doc in commandesSnapshot.docs) {
        final data = doc.data();
        revenus += (data['commission'] ?? 0.0).toDouble();
      }
      _revenusTotal = revenus;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Administration',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Statistiques globales
                    Text(
                      'Vue d\'ensemble',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),

                    // Grille de statistiques
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Artisans',
                          _totalArtisans.toString(),
                          Icons.construction,
                          AppColors.primaryBlue,
                        ),
                        _buildStatCard(
                          'En attente',
                          _artisansEnAttente.toString(),
                          Icons.pending,
                          AppColors.warning,
                        ),
                        _buildStatCard(
                          'Clients',
                          _totalClients.toString(),
                          Icons.people,
                          AppColors.success,
                        ),
                        _buildStatCard(
                          'Commandes',
                          _totalCommandes.toString(),
                          Icons.shopping_bag,
                          AppColors.accentRed,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Revenus
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Revenus totaux (commissions)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_revenusTotal.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Actions rapides
                    Text(
                      'Actions rapides',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),

                    _buildActionButton(
                      'Valider les artisans',
                      Icons.check_circle_outline,
                      AppColors.success,
                      () {
                        context.go('/admin/validate-artisans');
                      },
                      badge: _artisansEnAttente > 0 ? _artisansEnAttente.toString() : null,
                    ),

                    const SizedBox(height: 12),

                    _buildActionButton(
                      'Gérer les agents',
                      Icons.badge,
                      AppColors.primaryBlue,
                      () {
                        context.go('/admin/manage-agents');
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildActionButton(
                      'Signalements et litiges',
                      Icons.report_problem,
                      AppColors.warning,
                      () {
                        // TODO: Navigation vers signalements
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildActionButton(
                      'Transactions',
                      Icons.payment,
                      AppColors.accentRed,
                      () {
                        // TODO: Navigation vers transactions
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fonctionnalité en cours de développement')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.greyDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.greyMedium),
          ],
        ),
      ),
    );
  }
}

