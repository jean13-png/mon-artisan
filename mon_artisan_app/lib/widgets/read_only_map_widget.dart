import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

/// Un widget de carte simple en lecture seule pour afficher une position.
class ReadOnlyMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;
  final String? label;

  const ReadOnlyMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 160,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final position = ll.LatLng(latitude, longitude);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyMedium),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.monartisan.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.accentRed,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Badge optionnel
            if (label != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        label!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Attribution OSM
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: AppColors.white.withOpacity(0.6),
                child: const Text(
                  '© OSM',
                  style: TextStyle(fontSize: 8, color: AppColors.greyDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
