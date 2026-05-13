import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';

class AdminTransactionsScreen extends StatelessWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Transactions',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection('commandes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Filtrer les commandes qui ont un montant ou une commission
          final transactions = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('montant') || data.containsKey('commission');
          }).toList();

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: AppColors.greyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune transaction',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les transactions apparaîtront ici.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final data = transactions[index].data() as Map<String, dynamic>;
              final montant = (data['montant'] ?? 0).toDouble();
              final commission = (data['commission'] ?? 0).toDouble();
              final status = data['status'] ?? 'inconnu';
              
              DateTime? date;
              if (data['createdAt'] is Timestamp) {
                date = (data['createdAt'] as Timestamp).toDate();
              }

              final dateStr = date != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                  : 'Date inconnue';

              Color statusColor;
              String statusText;

              switch (status) {
                case 'completed':
                case 'payed':
                  statusColor = AppColors.success;
                  statusText = 'Payé';
                  break;
                case 'cancelled':
                  statusColor = AppColors.error;
                  statusText = 'Annulé';
                  break;
                case 'pending':
                default:
                  statusColor = AppColors.warning;
                  statusText = 'En attente';
                  break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppColors.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Montant: ${montant.toStringAsFixed(0)} FCFA',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Commission: ${commission.toStringAsFixed(0)} FCFA',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
