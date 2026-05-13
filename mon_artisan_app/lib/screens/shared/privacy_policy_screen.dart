import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Politique de confidentialité',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de Confidentialité',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 16),
            Text(
              '1. Collecte des données\n'
              'Nous collectons les données nécessaires au bon fonctionnement de l\'application (nom, prénom, email, localisation pour les artisans).\n\n'
              '2. Utilisation des données\n'
              'Vos données sont utilisées uniquement pour vous mettre en relation (client-artisan) et améliorer nos services.\n\n'
              '3. Protection des données\n'
              'Nous mettons en place des mesures de sécurité pour protéger vos informations personnelles contre tout accès non autorisé.\n\n'
              '4. Vos droits\n'
              'Vous avez le droit d\'accéder à vos données, de les modifier ou de demander leur suppression à tout moment via l\'application ou en nous contactant.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
