import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../models/artisan_model.dart';
import '../../widgets/custom_button.dart';
import '../shared/chat_screen.dart';

class ArtisanProfileScreen extends StatelessWidget {
  final ArtisanModel artisan;

  const ArtisanProfileScreen({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      body: CustomScrollView(
        slivers: [
          // AppBar avec photo de profil
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: artisan.photoUrl != null && artisan.photoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: artisan.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: AppColors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primaryBlue,
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.primaryBlue,
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations principales
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artisan.fullName.isNotEmpty ? artisan.fullName : 'Artisan',
                                  style: AppTextStyles.h2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  artisan.metier,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (artisan.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Vérifié',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Note et avis
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artisan.noteGlobale.toStringAsFixed(1),
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${artisan.nombreAvis} avis)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.greyDark,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.greyDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${artisan.ville} - ${artisan.quartier}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.greyDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Statistiques
                      Row(
                        children: [
                          _buildStatItem(
                            Icons.work_outline,
                            '${artisan.nombreCommandes}',
                            'Commandes',
                          ),
                          const SizedBox(width: 24),
                          _buildStatItem(
                            Icons.access_time,
                            '${artisan.experience}',
                            'Ans d\'exp.',
                          ),
                          const SizedBox(width: 24),
                          _buildStatItem(
                            Icons.location_searching,
                            '${artisan.rayonAction}',
                            'km rayon',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À propos',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        artisan.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyDark,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tarifs
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarifs',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTarifCard(
                              'Tarif horaire',
                              artisan.tarifs['tarifHoraire'] != null 
                                  ? '${artisan.tarifs['tarifHoraire']} FCFA'
                                  : (artisan.tarifs['horaire'] != null 
                                      ? '${artisan.tarifs['horaire']} FCFA'
                                      : 'Sur devis'),
                              Icons.access_time,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTarifCard(
                              'Tarif journalier',
                              artisan.tarifs['tarifJournalier'] != null 
                                  ? '${artisan.tarifs['tarifJournalier']} FCFA'
                                  : (artisan.tarifs['journalier'] != null 
                                      ? '${artisan.tarifs['journalier']} FCFA'
                                      : 'Sur devis'),
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      if (artisan.tarifs['deplacementInclus'] == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Déplacement inclus',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Galerie photos
                if (artisan.photos.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réalisations',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: artisan.photos.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(artisan.photos[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Certifications
                if (artisan.certifications.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certifications',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 12),
                        ...artisan.certifications.map((cert) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  size: 20,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cert,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Avis clients (TODO: implémenter la liste complète)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Avis clients',
                            style: AppTextStyles.h3,
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to all reviews
                            },
                            child: Text(
                              'Voir tout',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Les avis seront affichés ici',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // Espace pour le bouton fixe
              ],
            ),
          ),
        ],
      ),
      
      // Bouton Commander fixe en bas
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  // Appeler l'artisan si le numéro est disponible
                  final tel = artisan.telephone;
                  if (tel == null || tel.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Numéro non disponible'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  final uri = Uri(scheme: 'tel', path: tel);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(
                  Icons.phone,
                  color: AppColors.primaryBlue,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // Ouvrir le chat avec l'artisan
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserId: artisan.userId,
                        otherUserName: artisan.fullName.isNotEmpty ? artisan.fullName : 'Artisan',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.success,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Commander',
                  onPressed: () {
                    context.push(
                      AppRouter.selectCommandeType,
                      extra: artisan,
                    );
                  },
                  backgroundColor: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.greyDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTarifCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.greyDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
