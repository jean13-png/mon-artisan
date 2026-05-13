import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Signalements et litiges',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection('signalements')
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

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun signalement',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tout se passe bien sur la plateforme.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final motif = data['motif'] ?? 'Motif non spécifié';
              final description = data['description'] ?? 'Aucune description';
              final status = data['status'] ?? 'pending';

              Color statusColor;
              String statusText;
              IconData statusIcon;

              switch (status) {
                case 'resolved':
                  statusColor = AppColors.success;
                  statusText = 'Résolu';
                  statusIcon = Icons.check_circle;
                  break;
                case 'rejected':
                  statusColor = AppColors.error;
                  statusText = 'Rejeté';
                  statusIcon = Icons.cancel;
                  break;
                case 'pending':
                default:
                  statusColor = AppColors.warning;
                  statusText = 'En attente';
                  statusIcon = Icons.pending;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              motif,
                              style: AppTextStyles.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 16, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTextStyles.bodyMedium,
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
