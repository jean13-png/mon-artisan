import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/services/firebase_service.dart';
import '../screens/shared/location_picker_screen.dart';
import '../widgets/map_picker_widget.dart';

class ShareLocationDialog {
  static Future<void> show({
    required BuildContext context,
    required String commandeId,
    required String artisanId,
  }) async {
    final bool? wantToShare = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
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
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
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
      ),
    );

    if (wantToShare == true && context.mounted) {
      final result = await Navigator.push<MapPosition>(
        context,
        MaterialPageRoute(
          builder: (_) => const LocationPickerScreen(
            titre: 'Confirmer votre position',
            labelBoutonConfirm: 'Partager cette position',
          ),
        ),
      );

      if (result != null && context.mounted) {
        await _sauvegarderEtNotifier(
          context: context,
          commandeId: commandeId,
          artisanId: artisanId,
          pos: result,
        );
      }
    }
  }

  static Future<void> _sauvegarderEtNotifier({
    required BuildContext context,
    required String commandeId,
    required String artisanId,
    required MapPosition pos,
  }) async {
    // Afficher un loader discret
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loaderContext) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      ),
    );

    try {
      // 1. Sauvegarder dans la commande
      print('[INFO] Sauvegarde de la position dans Firestore...');
      await FirebaseService.commandesCollection.doc(commandeId).update({
        'clientPosition': GeoPoint(pos.latitude, pos.longitude),
        'clientAdresseExacte': pos.adresseComplete,
        'clientQuartier': pos.quartier,
        'clientRue': pos.rue,
        'clientVille': pos.ville,
        'clientPositionPartagee': true,
        'datePartagePosition': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      print('[SUCCESS] Position sauvegardée');

      // 2. Envoyer notification à l'artisan
      try {
        await FirebaseService.firestore.collection('notifications').add({
          'userId': artisanId,
          'type': 'position_partagee',
          'titre': 'Position partagée',
          'message': 'Le client a partagé sa position : ${pos.adresseComplete}',
          'data': {
            'commandeId': commandeId,
            'adresse': pos.adresseComplete,
            'latitude': pos.latitude,
            'longitude': pos.longitude,
          },
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
        print('[SUCCESS] Notification envoyée à l\'artisan');
      } catch (e) {
        print('[WARNING] Erreur envoi notification: $e');
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Fermer le loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Position partagée avec l\'artisan'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('[ERROR] Erreur partage localisation: $e');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
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
