import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Conditions d\'utilisation',
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
              'Conditions d\'Utilisation',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 16),
            Text(
              '1. Acceptation des conditions\n'
              'En utilisant Mon Artisan, vous acceptez d\'être lié par les présentes conditions d\'utilisation.\n\n'
              '2. Services fournis\n'
              'L\'application sert de plateforme de mise en relation entre des clients et des artisans qualifiés.\n\n'
              '3. Engagements de l\'utilisateur\n'
              'Vous vous engagez à fournir des informations exactes et à utiliser l\'application de manière respectueuse et légale.\n\n'
              '4. Responsabilité\n'
              'Mon Artisan agit en tant qu\'intermédiaire. La qualité des prestations relève de la responsabilité de l\'artisan.\n\n'
              '5. Modification des conditions\n'
              'Nous nous réservons le droit de modifier ces conditions à tout moment. Les utilisateurs seront informés de tout changement.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
