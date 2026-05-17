import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class ArtisanReviewsScreen extends StatelessWidget {
  final String artisanId;

  const ArtisanReviewsScreen({super.key, required this.artisanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis de l\'artisan'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Text(
          'Tous les avis pour l\'artisan ID: $artisanId seront affichés ici.',
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }
}
