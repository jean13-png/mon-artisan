import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../models/artisan_model.dart';

class ArtisanCard extends StatelessWidget {
  final ArtisanModel artisan;
  final double? distance;
  final VoidCallback onTap;

  const ArtisanCard({
    super.key,
    required this.artisan,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool disponible = artisan.estRealementDisponible;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: disponible
                  ? null
                  : Border.all(color: AppColors.greyMedium.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: disponible ? 0.08 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: disponible ? 0.1 : 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: artisan.photoUrl != null && artisan.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: artisan.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: disponible ? AppColors.primaryBlue : AppColors.greyMedium,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: disponible ? AppColors.primaryBlue : AppColors.greyMedium,
                              size: 30,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: disponible ? AppColors.primaryBlue : AppColors.greyMedium,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom + indicateur disponibilité + vérifié
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              artisan.fullName.isNotEmpty
                                  ? artisan.fullName
                                  : artisan.prenom != null
                                      ? '${artisan.prenom} ${artisan.nom ?? ''}'.trim()
                                      : 'Artisan',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: disponible ? null : AppColors.greyDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Point coloré de disponibilité
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: disponible ? AppColors.success : AppColors.greyMedium,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (artisan.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified, size: 15, color: AppColors.success),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Métier + "Indisponible" si besoin
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              artisan.metier,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: disponible ? AppColors.primaryBlue : AppColors.greyMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!disponible)
                            Text(
                              'Indisponible',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.greyMedium,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Localisation + distance
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: AppColors.greyDark),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${artisan.ville} - ${artisan.quartier}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (distance != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${distance!.toStringAsFixed(1)} km',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Note + tarif
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${artisan.noteGlobale.toStringAsFixed(1)} (${artisan.nombreAvis} avis)',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                          ),
                          const Spacer(),
                          Text(
                            '${(artisan.tarifs['horaire'] ?? artisan.tarifs['tarifHoraire'] ?? 0).toStringAsFixed(0)} FCFA/h',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: disponible ? AppColors.primaryBlue : AppColors.greyMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.greyDark.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
