import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/services/geolocation_service.dart';
import '../core/services/firebase_service.dart';

class ShareLocationDialog {
  static Future<void> show({
    required BuildContext context,
    required String commandeId,
    required String artisanId,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primaryBlue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Partager votre position',
                style: AppTextStyles.h3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour que l\'artisan puisse vous localiser facilement, partagez votre position exacte.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre position est sécurisée et visible uniquement par cet artisan',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.greyDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Plus tard',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.greyDark,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _partagerLocalisation(
                context: context,
                commandeId: commandeId,
                artisanId: artisanId,
              );
            },
            icon: const Icon(Icons.my_location, size: 20),
            label: const Text('Partager ma position'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _partagerLocalisation({
    required BuildContext context,
    required String commandeId,
    required String artisanId,
  }) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loaderContext) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Récupération de votre position...',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // 1. Obtenir la position GPS
      print('[INFO] Récupération de la position GPS...');
      final position = await GeolocationService.getCurrentPosition();
      print('[SUCCESS] Position obtenue: ${position.latitude}, ${position.longitude}');

      // 2. Obtenir l'adresse lisible via geocoding
      String adresseComplete = 'Position GPS partagée';
      try {
        print('[INFO] Récupération de l\'adresse...');
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          adresseComplete = [
            placemark.street,
            placemark.subLocality,
            placemark.locality,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          print('[SUCCESS] Adresse: $adresseComplete');
        }
      } catch (e) {
        print('[WARNING] Erreur récupération adresse: $e');
        // Continuer avec l'adresse par défaut
      }

      // 3. Sauvegarder dans la commande
      print('[INFO] Sauvegarde de la position dans Firestore...');
      await FirebaseService.commandesCollection.doc(commandeId).update({
        'clientPosition': GeoPoint(position.latitude, position.longitude),
        'clientAdresseExacte': adresseComplete,
        'clientPositionPartagee': true,
        'datePartagePosition': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      print('[SUCCESS] Position sauvegardée');

      // 4. Envoyer notification à l'artisan
      try {
        await FirebaseService.firestore.collection('notifications').add({
          'userId': artisanId,
          'type': 'position_partagee',
          'titre': 'Position partagée',
          'message': 'Le client a partagé sa position avec vous',
          'data': {
            'commandeId': commandeId,
            'adresse': adresseComplete,
          },
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
        print('[SUCCESS] Notification envoyée à l\'artisan');
      } catch (e) {
        print('[WARNING] Erreur envoi notification: $e');
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await Future.delayed(const Duration(milliseconds: 100));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Position partagée avec l\'artisan',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Erreur partage localisation: $e');

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur: ${e.toString()}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
