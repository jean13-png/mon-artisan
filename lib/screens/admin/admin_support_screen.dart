import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../providers/commande_provider.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  String _filter = 'nouveau';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Support artisans',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                _buildFilterChip('Nouveaux', 'nouveau'),
                const SizedBox(width: 8),
                _buildFilterChip('Tous', 'all'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filter == 'nouveau'
                  ? FirebaseService.firestore
                      .collection('support_messages')
                      .where('status', isEqualTo: 'nouveau')
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                  : FirebaseService.firestore
                      .collection('support_messages')
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
                        Icon(Icons.support_agent_outlined, size: 64, color: AppColors.greyMedium),
                        const SizedBox(height: 16),
                        Text('Aucun message de support', style: AppTextStyles.bodyLarge),
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
                    final artisanId = data['artisanId'] ?? '';
                    final message = data['message'] ?? '';
                    final reponse = data['reponse'] ?? '';
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final status = data['status'] ?? 'nouveau';

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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: status == 'nouveau'
                                      ? AppColors.error.withOpacity(0.1)
                                      : AppColors.success.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.support_agent,
                                  color: status == 'nouveau' ? AppColors.error : AppColors.success,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Artisan: ${artisanId.substring(0, 8)}',
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'nouveau'
                                      ? AppColors.error.withOpacity(0.1)
                                      : AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status == 'nouveau' ? 'Nouveau' : 'Répondu',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: status == 'nouveau' ? AppColors.error : AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(message, style: AppTextStyles.bodyMedium),
                          if (reponse.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.greyLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Réponse: $reponse', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark)),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: status == 'nouveau'
                                      ? () => _showReponseDialog(context, docs[index].id, artisanId)
                                      : null,
                                  icon: const Icon(Icons.reply, size: 18),
                                  label: Text(status == 'nouveau' ? 'Répondre' : 'Envoyé'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    disabledBackgroundColor: AppColors.greyMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showSignalementArtisanDialog(context, artisanId),
                                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                                  label: const Text('Signalement / fiche client'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.greyLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.greyDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showReponseDialog(BuildContext context, String messageId, String artisanId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Répondre au support', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Votre réponse...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await FirebaseService.firestore.collection('support_messages').doc(messageId).update({
                  'reponse': controller.text.trim(),
                  'reponseAt': Timestamp.now(),
                  'status': 'repondu',
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Réponse envoyée'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text('Envoyer', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showSignalementArtisanDialog(BuildContext context, String artisanId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Signalement / Action artisan', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artisan ID: $artisanId', style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark)),
            const SizedBox(height: 12),
            Text('Vous pouvez annuler toutes les commandes en cours de cet artisan et favoriser sa visibilité dans les recherches.', style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirmer l\'action', style: AppTextStyles.h3),
                  content: Text('Annuler toutes les commandes en cours et favoriser la visibilité de l\'artisan $artisanId ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler', style: AppTextStyles.bodyMedium)),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: Text('Confirmer', style: AppTextStyles.button)),
                  ],
                ),
              );

              if (confirmed != true) return;

              if (!mounted) return;

              final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                await commandeProvider.annulerToutesCommandesArtisan(artisanId);
                await FirebaseService.firestore.collection('priorites_artisans').doc(artisanId).set({
                  'artisanId': artisanId,
                  'boostVisibilite': true,
                  'dateBoost': Timestamp.now(),
                  'raison': 'Signalement client / problème',
                }, SetOptions(merge: true));

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Actions appliquées : commandes annulées, visibilité favorisée'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Traiter', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}
