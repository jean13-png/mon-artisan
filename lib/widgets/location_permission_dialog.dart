import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const LocationPermissionDialog({
    super.key,
    required this.onPermissionGranted,
    this.onPermissionDenied,
  });

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        onPermissionGranted: () => Navigator.of(context).pop(true),
        onPermissionDenied: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  Future<void> _requestPermission(BuildContext context) async {
    // Vérifier si le service de localisation est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showLocationServiceDialog(context);
      }
      return;
    }

    // Demander la permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return;
    }

    // Permission accordée
    onPermissionGranted();
  }

  void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service de localisation désactivé'),
        content: const Text(
          'Veuillez activer le service de localisation dans les paramètres de votre téléphone pour trouver les artisans près de vous.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onPermissionDenied != null) {
                onPermissionDenied!();
              }
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission refusée'),
        content: const Text(
          'L\'accès à votre localisation est nécessaire pour trouver les artisans près de vous. Vous pouvez activer la permission dans les paramètres.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onPermissionDenied != null) {
                onPermissionDenied!();
              }
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Titre
            Text(
              'Activer la localisation',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Pour vous montrer les artisans les plus proches de vous, nous avons besoin d\'accéder à votre position.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.greyDark,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Avantages
            _buildBenefit('Trouvez les artisans près de chez vous'),
            _buildBenefit('Temps de déplacement réduit'),
            _buildBenefit('Service plus rapide'),
            
            const SizedBox(height: 24),
            
            // Boutons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _requestPermission(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Activer la localisation',
                  style: AppTextStyles.button,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextButton(
              onPressed: () {
                if (onPermissionDenied != null) {
                  onPermissionDenied!();
                } else {
                  Navigator.of(context).pop(false);
                }
              },
              child: Text(
                'Plus tard',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.greyDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: AppColors.success,
          ),
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
}
