import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../core/routes/app_router.dart';
import '../../models/commande_model.dart';

class AdminTransactionsScreen extends StatelessWidget {
  const AdminTransactionsScreen({super.key});

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
              context.go(AppRouter.adminDashboard);
            }
          },
        ),
        title: Text(
          'Toutes les transactions',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection('commandes')
            .where('paiementStatut', whereIn: ['paye', 'bloque', 'debloque', 'rembourse'])
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Aucune transaction trouvée'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final commande = CommandeModel.fromFirestore(docs[index]);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(commande.paiementStatut).withOpacity(0.1),
                    child: Icon(
                      _getStatusIcon(commande.paiementStatut),
                      color: _getStatusColor(commande.paiementStatut),
                    ),
                  ),
                  title: Text(
                    '${(commande.montantDevis ?? commande.montant).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${commande.metier} • ${commande.id.substring(0, 8)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getStatusLabel(commande.paiementStatut),
                        style: TextStyle(
                          color: _getStatusColor(commande.paiementStatut),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${commande.updatedAt.day}/${commande.updatedAt.month}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push(AppRouter.commandeDetail, extra: commande);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'paye': return AppColors.success;
      case 'bloque': return AppColors.warning;
      case 'debloque': return AppColors.primaryBlue;
      case 'rembourse': return AppColors.error;
      default: return AppColors.greyMedium;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'paye': return Icons.check_circle;
      case 'bloque': return Icons.lock;
      case 'debloque': return Icons.lock_open;
      case 'rembourse': return Icons.history;
      default: return Icons.payment;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'paye': return 'Validé';
      case 'bloque': return 'Escrow';
      case 'debloque': return 'Débloqué';
      case 'rembourse': return 'Remboursé';
      default: return 'Inconnu';
    }
  }
}
