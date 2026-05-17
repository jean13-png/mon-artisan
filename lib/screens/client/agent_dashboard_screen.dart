import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/auth_provider.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  bool _isLoading = true;
  double _revenuJournalier = 0;
  double _revenuMensuel = 0;
  double _revenuTotal = 0;
  double _revenuDisponibles = 0;
  int _totalProspects = 0;
  List<Map<String, dynamic>> _recentProspects = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;
      if (user == null) return;

      // 1. Chercher les parrainages dans collection 'users'
      final prospectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('roles', arrayContains: 'artisan')
          .where('agentParrainId', isEqualTo: user.id)
          .where('paiementInscription', isEqualTo: true)
          .get();

      _totalProspects = prospectsSnapshot.docs.length;
      
      // 2. Récupérer les revenus directement depuis l'utilisateur (source de vérité créditée)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
      final userData = userDoc.data();
      
      if (userData != null) {
        _revenuTotal = (userData['agentRevenusTotal'] ?? 0.0).toDouble();
        _revenuDisponibles = (userData['agentRevenusDisponibles'] ?? 0.0).toDouble();
      }

      // Statistiques journalières et mensuelles
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      int dailyCount = 0;
      int monthlyCount = 0;

      for (var doc in prospectsSnapshot.docs) {
        final data = doc.data();
        final datePaiement = (data['datePaiementInscription'] as Timestamp?)?.toDate();
        
        if (datePaiement != null) {
          if (datePaiement.isAfter(todayStart)) dailyCount++;
          if (datePaiement.isAfter(monthStart)) monthlyCount++;
        }
      }

      _revenuJournalier = dailyCount * 300.0;
      _revenuMensuel = monthlyCount * 300.0;

      // Récupérer les 5 derniers prospects
      _recentProspects = prospectsSnapshot.docs
          .map((doc) => doc.data())
          .take(5)
          .toList();

    } catch (e) {
      print('[ERROR] Erreur stats agent: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: const Text('Espace Agent'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte du Code Promo
                  _buildPromoCodeCard(user?.codePromoAgent ?? 'N/A'),
                  const SizedBox(height: 24),
                  
                  Text('Mes Revenus', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  
                  // Grille de stats
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Aujourd\'hui', '${_revenuJournalier.toStringAsFixed(0)} F', Icons.today, AppColors.success),
                      _buildStatCard('Ce mois', '${_revenuMensuel.toStringAsFixed(0)} F', Icons.calendar_month, AppColors.primaryBlue),
                      _buildStatCard('Disponible', '${_revenuDisponibles.toStringAsFixed(0)} F', Icons.account_balance_wallet, AppColors.success),
                      _buildStatCard('Total cumulé', '${_revenuTotal.toStringAsFixed(0)} F', Icons.account_balance, AppColors.accentRed),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Text('Dernières inscriptions', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  
                  if (_recentProspects.isEmpty)
                    const Center(child: Text('Aucune inscription pour le moment.'))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentProspects.length,
                      itemBuilder: (context, index) {
                        final prospect = _recentProspects[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text('${prospect['prenom']} ${prospect['nom']}'),
                            subtitle: Text(prospect['metier'] ?? 'Artisan'),
                            trailing: const Text('+300 F', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPromoCodeCard(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryBlue, Color(0xFF1E88E5)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text('VOTRE CODE PARRAINAGE', style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 4)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Partagez ce code aux artisans. Vous gagnez 300F dès qu\'ils finalisent leur inscription.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.greyDark)),
            ],
          ),
        ],
      ),
    );
  }
}
