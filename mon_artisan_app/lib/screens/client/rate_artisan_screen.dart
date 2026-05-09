import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/custom_button.dart';

class RateArtisanScreen extends StatefulWidget {
  final String commandeId;
  final String artisanId;
  final String artisanName;

  const RateArtisanScreen({
    super.key,
    required this.commandeId,
    required this.artisanId,
    required this.artisanName,
  });

  @override
  State<RateArtisanScreen> createState() => _RateArtisanScreenState();
}

class _RateArtisanScreenState extends State<RateArtisanScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final commandeProvider =
          Provider.of<CommandeProvider>(context, listen: false);

      final success = await commandeProvider.noterArtisan(
        commandeId: widget.commandeId,
        artisanId: widget.artisanId,
        note: _rating.toDouble(),
        commentaire: _commentController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Merci pour votre avis !'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(commandeProvider.errorMessage ?? 'Erreur lors de l\'envoi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Noter l\'artisan',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            // Icône
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              widget.artisanName,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Comment évaluez-vous cette prestation ?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.greyDark,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Étoiles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: AppColors.warning,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            if (_rating > 0)
              Text(
                _getRatingText(_rating),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Commentaire
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commentaire (optionnel)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Partagez votre expérience...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.greyMedium,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.greyMedium),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryBlue),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bouton soumettre
            CustomButton(
              text: _isSubmitting ? 'Envoi en cours...' : 'Envoyer mon avis',
              onPressed: _isSubmitting 
                  ? null 
                  : () {
                      _submitRating();
                    },
              backgroundColor: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Très insatisfait';
      case 2:
        return 'Insatisfait';
      case 3:
        return 'Moyen';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Très satisfait';
      default:
        return '';
    }
  }
}
