import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';

class AdminAnnulationFeedbacksScreen extends StatelessWidget {
  const AdminAnnulationFeedbacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
            "Avis d'annulation",
            style: AppTextStyles.h3.copyWith(color: AppColors.white),
          ),
        ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.firestore
            .collection('annulation_feedbacks')
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
                  Icon(Icons.feedback_outlined, size: 64, color: AppColors.greyMedium),
                  const SizedBox(height: 16),
                  Text("Aucun avis d'annulation", style: AppTextStyles.bodyLarge),
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
              final motif = data['motif'] ?? 'Motif inconnu';
              final commentaire = data['commentaire'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final commandeId = data['commandeId'] ?? '';
              final clientId = data['clientId'] ?? '';
              final artisanId = data['artisanId'] ?? '';

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cancel, color: AppColors.error, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                motif,
                                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Le ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (commentaire.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(commentaire, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Client: $clientId', style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark)),
                        const SizedBox(width: 16),
                        Text('Artisan: $artisanId', style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark)),
                      ],
                    ),
                    if (commandeId.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Commande: #${commandeId.substring(0, 8)}', style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
