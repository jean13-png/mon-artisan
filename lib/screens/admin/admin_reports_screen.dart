import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../core/routes/app_router.dart';
import 'user_detail_screen.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

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
              final reporterId = data['reporterId'];
              final reportedArtisanId = data['reportedArtisanId'];

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
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      // Infos Reporter
                      _buildUserLink(
                        context,
                        'Signalé par: ${data['reporterName'] ?? 'Utilisateur inconnu'}',
                        Icons.person_outline,
                        reporterId,
                        'client'
                      ),
                      const SizedBox(height: 8),
                      
                      // Infos Reported Artisan
                      _buildUserLink(
                        context,
                        'Artisan concerné: ${data['artisanName'] ?? 'Non spécifié'}',
                        Icons.engineering_outlined,
                        reportedArtisanId,
                        'artisan'
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateReportStatus(docs[index].id, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                ),
                                child: const Text('Rejeter'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateReportStatus(docs[index].id, 'resolved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.white,
                                ),
                                child: const Text('Résoudre'),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildUserLink(BuildContext context, String text, IconData icon, String? userId, String userType) {
    return InkWell(
      onTap: userId != null ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => UserDetailScreen(
              userId: userId,
              userType: userType,
            ),
          ),
        );
      } : null,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryBlue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReportStatus(String reportId, String newStatus) async {
    try {
      await FirebaseService.firestore
          .collection('signalements')
          .doc(reportId)
          .update({
        'status': newStatus,
        'resolvedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('[ERROR] Erreur mise à jour signalement: $e');
    }
  }
}
