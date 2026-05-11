import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/routes/app_router.dart';
import '../models/artisan_model.dart';

class ArtisanCard extends StatelessWidget {
  final ArtisanModel artisan;
  final double? distance; // Distance en km
  final VoidCallback onTap;

  const ArtisanCard({
    super.key,
    required this.artisan,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            context.push(
              '${AppRouter.artisanProfile}?id=${artisan.id}',
              extra: artisan,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.08),
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
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (artisan.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Vérifié',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artisan.metier,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.greyDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${artisan.ville} - ${artisan.quartier}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.greyDark,
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${artisan.noteGlobale.toStringAsFixed(1)} (${artisan.nombreAvis} avis)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.greyDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(artisan.tarifs['horaire'] ?? artisan.tarifs['tarifHoraire'] ?? 0).toStringAsFixed(0)} FCFA/h',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryBlue,
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
