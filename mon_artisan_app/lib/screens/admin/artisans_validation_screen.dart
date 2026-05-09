import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../models/artisan_model.dart';

class ArtisansValidationScreen extends StatefulWidget {
  const ArtisansValidationScreen({super.key});

  @override
  State<ArtisansValidationScreen> createState() => _ArtisansValidationScreenState();
}

class _ArtisansValidationScreenState extends State<ArtisansValidationScreen> {
  String _filter = 'pending'; // pending, approved, rejected

  Stream<QuerySnapshot> _getArtisansStream() {
    print('[FILTER] Filter: $_filter');
    
    if (_filter == 'pending') {
      // Pour "en attente", chercher les artisans NON vérifiés
      // (peu importe isProfileComplete)
      return FirebaseService.firestore
          .collection('artisans')
          .where('isVerified', isEqualTo: false)
          .snapshots();
    } else if (_filter == 'approved') {
      // Pour "approuvés", chercher les artisans vérifiés
      return FirebaseService.firestore
          .collection('artisans')
          .where('isVerified', isEqualTo: true)
          .snapshots();
    } else {
      // Pour "rejetés", chercher avec verificationStatus='rejected'
      return FirebaseService.firestore
          .collection('artisans')
          .where('verificationStatus', isEqualTo: 'rejected')
          .snapshots();
    }
  }

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
          'Validation des artisans',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                _buildFilterChip('En attente', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Approuvés', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejetés', 'rejected'),
              ],
            ),
          ),

          // Liste des artisans
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getArtisansStream(),
              builder: (context, snapshot) {
                print('[STREAM] Stream state: ${snapshot.connectionState}');
                print('[STREAM] Has data: ${snapshot.hasData}');
                print('[STREAM] Docs count: ${snapshot.data?.docs.length ?? 0}');
                print('[STREAM] Has error: ${snapshot.hasError}');
                if (snapshot.hasError) {
                  print('[ERROR] Error: ${snapshot.error}');
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: AppTextStyles.h3.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppColors.greyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun artisan',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.greyDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final artisan = ArtisanModel.fromFirestore(doc);
                    return _buildArtisanCard(artisan);
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
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.greyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.greyMedium,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.greyDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildArtisanCard(ArtisanModel artisan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                backgroundImage: artisan.photoUrl != null
                    ? NetworkImage(artisan.photoUrl!)
                    : null,
                child: artisan.photoUrl == null
                    ? Icon(Icons.person, color: AppColors.primaryBlue)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${artisan.prenom ?? ''} ${artisan.nom ?? ''}'.trim(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artisan.metier,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Informations
          _buildInfoRow(Icons.location_on, '${artisan.ville} - ${artisan.quartier}'),
          _buildInfoRow(Icons.phone, artisan.telephone ?? 'N/A'),
          _buildInfoRow(Icons.email, artisan.email ?? 'N/A'),
          _buildInfoRow(
            Icons.check_circle,
            artisan.isProfileComplete ? 'Profil complet' : 'Profil incomplet',
          ),

          if (artisan.verificationStatus == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectArtisan(artisan.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveArtisan(artisan.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Approuver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (artisan.verificationStatus == 'approved')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Artisan approuvé',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (artisan.verificationStatus == 'rejected')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Artisan rejeté',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.greyDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.greyDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveArtisan(String artisanId) async {
    try {
      // Récupérer les infos de l'artisan
      final artisanDoc = await FirebaseService.firestore
          .collection('artisans')
          .doc(artisanId)
          .get();
      
      if (!artisanDoc.exists) return;
      
      final artisanData = artisanDoc.data()!;
      final userId = artisanData['userId'];
      
      // Mettre à jour le statut
      await FirebaseService.firestore
          .collection('artisans')
          .doc(artisanId)
          .update({
        'verificationStatus': 'approved',
        'isVerified': true,
        'disponibilite': true,
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour l'artisan
      await FirebaseService.firestore
          .collection('notifications')
          .add({
        'userId': userId,
        'title': 'Profil approuvé',
        'message': 'Félicitations ! Votre profil artisan a été approuvé. Vous pouvez maintenant recevoir des commandes.',
        'type': 'validation',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text('Artisan approuvé et notifié'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Erreur approbation: $e');
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

  Future<void> _rejectArtisan(String artisanId) async {
    // Dialogue de confirmation avec raison
    String? raison;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final raisonController = TextEditingController();
        return AlertDialog(
          title: Text('Rejeter l\'artisan', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Êtes-vous sûr de vouloir rejeter cet artisan ?',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: raisonController,
                decoration: const InputDecoration(
                  labelText: 'Raison du rejet (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                raison = raisonController.text.trim();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Rejeter'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Récupérer les infos de l'artisan
      final artisanDoc = await FirebaseService.firestore
          .collection('artisans')
          .doc(artisanId)
          .get();
      
      if (!artisanDoc.exists) return;
      
      final artisanData = artisanDoc.data()!;
      final userId = artisanData['userId'];
      
      // Mettre à jour le statut
      await FirebaseService.firestore
          .collection('artisans')
          .doc(artisanId)
          .update({
        'verificationStatus': 'rejected',
        'isVerified': false,
        'disponibilite': false,
        'rejectionReason': raison ?? '',
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour l'artisan
      final message = raison != null && raison!.isNotEmpty
          ? 'Votre profil a été rejeté. Raison: $raison'
          : 'Votre profil a été rejeté. Veuillez corriger les informations et soumettre à nouveau.';
      
      await FirebaseService.firestore
          .collection('notifications')
          .add({
        'userId': userId,
        'title': 'Profil rejeté',
        'message': message,
        'type': 'validation',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.white),
                SizedBox(width: 8),
                Text('Artisan rejeté et notifié'),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Erreur rejet: $e');
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
}

