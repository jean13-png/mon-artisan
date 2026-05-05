import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class MetierCard extends StatelessWidget {
  final String nom;
  final String iconName;
  final VoidCallback onTap;
  final int? nombreArtisans;

  const MetierCard({
    super.key,
    required this.nom,
    required this.iconName,
    required this.onTap,
    this.nombreArtisans,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(iconName),
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nom,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (nombreArtisans != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$nombreArtisans artisan${nombreArtisans! > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.greyDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.greyMedium,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Mapping des noms d'icônes vers les IconData
    switch (iconName.toLowerCase()) {
      case 'bolt':
        return Icons.bolt;
      case 'wrench':
        return Icons.build;
      case 'hammer':
        return Icons.construction;
      case 'paint-roller':
        return Icons.format_paint;
      case 'saw':
        return Icons.carpenter;
      case 'grid':
        return Icons.grid_4x4;
      case 'ruler-combined':
        return Icons.straighten;
      case 'fire':
        return Icons.local_fire_department;
      case 'layer-group':
        return Icons.layers;
      case 'key':
        return Icons.vpn_key;
      case 'home':
        return Icons.home_repair_service;
      case 'window-maximize':
        return Icons.window;
      case 'th-large':
        return Icons.view_module;
      case 'border-all':
        return Icons.border_all;
      case 'solar-panel':
        return Icons.solar_power;
      case 'snowflake':
        return Icons.ac_unit;
      case 'temperature-high':
        return Icons.thermostat;
      case 'fire-alt':
        return Icons.local_gas_station;
      case 'industry':
        return Icons.factory;
      case 'tree':
        return Icons.park;
      case 'tint':
        return Icons.water_drop;
      case 'shield-alt':
        return Icons.shield;
      case 'palette':
        return Icons.palette;
      case 'spray-can':
        return Icons.format_paint;
      case 'hammer-war':
        return Icons.gavel;
      case 'mountain':
        return Icons.terrain;
      case 'cubes':
        return Icons.view_in_ar;
      case 'box':
        return Icons.inventory_2;
      case 'ladder':
        return Icons.stairs;
      case 'drafting-compass':
        return Icons.architecture;
      case 'building':
        return Icons.business;
      case 'map-marked-alt':
        return Icons.map;
      case 'map':
        return Icons.explore;
      case 'user-tie':
        return Icons.engineering;
      case 'elevator':
        return Icons.elevator;
      case 'home-lg-alt':
        return Icons.home;
      case 'bell':
        return Icons.security;
      case 'network-wired':
        return Icons.cable;
      case 'water':
        return Icons.water_damage;
      case 'recycle':
        return Icons.recycling;
      case 'swimming-pool':
        return Icons.pool;
      case 'tools':
        return Icons.handyman;
      case 'broom':
        return Icons.cleaning_services;
      case 'truck':
        return Icons.local_shipping;
      case 'puzzle-piece':
        return Icons.extension;
      case 'cut':
        return Icons.content_cut;
      case 'magic':
        return Icons.auto_fix_high;
      case 'spa':
        return Icons.spa;
      case 'user-alt':
        return Icons.face;
      case 'baby':
        return Icons.child_care;
      case 'user-nurse':
        return Icons.medical_services;
      case 'utensils':
        return Icons.restaurant;
      case 'birthday-cake':
        return Icons.cake;
      case 'gift':
        return Icons.card_giftcard;
      case 'camera':
        return Icons.camera_alt;
      case 'video':
        return Icons.videocam;
      case 'music':
        return Icons.music_note;
      case 'heart':
        return Icons.favorite;
      case 'car':
        return Icons.directions_car;
      case 'car-side':
        return Icons.car_repair;
      case 'mobile-alt':
        return Icons.phone_android;
      default:
        return Icons.work;
    }
  }
}