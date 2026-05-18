import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';

class AdminWithdrawalsScreen extends StatelessWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Gestion des retraits',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection('retraits')
            .orderBy('createdAt', descending: true)
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
                  Icon(Icons.payments_outlined, size: 64, color: AppColors.greyMedium),
                  const SizedBox(height: 16),
                  Text('Aucune demande de retrait', style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final status = data['statut'] ?? 'en_attente';
              final montant = (data['montant'] ?? 0.0).toDouble();
              final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return _buildWithdrawalCard(context, docId, data, montant, status, date);
            },
          );
        },
      ),
    );
  }

  Widget _buildWithdrawalCard(BuildContext context, String docId, Map<String, dynamic> data, double montant, String status, DateTime date) {
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'approuve':
        statusColor = AppColors.success;
        statusLabel = 'Approuvé';
        break;
      case 'rejete':
        statusColor = AppColors.error;
        statusLabel = 'Rejeté';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'En attente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${montant.toStringAsFixed(0)} FCFA',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Le ${date.day}/${date.month}/${date.year}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.bodySmall.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (status == 'en_attente') ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleWithdrawal(context, docId, false),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Rejeter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleWithdrawal(context, docId, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.white),
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleWithdrawal(BuildContext context, String docId, bool approved) async {
    try {
      // Récupérer les infos du retrait pour avoir l'artisanId et le montant
      final withdrawalDoc = await FirebaseService.firestore.collection('retraits').doc(docId).get();
      final withdrawalData = withdrawalDoc.data() as Map<String, dynamic>;
      final artisanUserId = withdrawalData['artisanId'];
      final montant = withdrawalData['montant'];

      await FirebaseService.firestore.collection('retraits').doc(docId).update({
        'statut': approved ? 'approuve' : 'rejete',
        'updatedAt': Timestamp.now(),
      });

      // Envoyer une notification à l'artisan
      await FirebaseService.firestore.collection('notifications').add({
        'userId': artisanUserId,
        'type': approved ? 'withdrawal_approved' : 'withdrawal_rejected',
        'titre': approved ? 'Retrait validé' : 'Retrait refusé',
        'message': approved
            ? 'Votre demande de retrait de $montant FCFA a été approuvée.'
            : 'Votre demande de retrait de $montant FCFA a été refusée par l\'administration.',
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Retrait validé' : 'Retrait rejeté'),
            backgroundColor: approved ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
