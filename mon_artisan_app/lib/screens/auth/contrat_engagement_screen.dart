import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class ContratEngagementScreen extends StatefulWidget {
  const ContratEngagementScreen({super.key});

  @override
  State<ContratEngagementScreen> createState() => _ContratEngagementScreenState();
}

class _ContratEngagementScreenState extends State<ContratEngagementScreen> {
  bool _hasAccepted = false;
  bool _isLoading = false;

  Future<void> _acceptContract() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id;

      if (userId == null) {
        _showError('Erreur: utilisateur non connecté');
        return;
      }

      // Enregistrer l'acceptation du contrat dans Firestore
      await FirebaseService.usersCollection.doc(userId).update({
        'contratAccepte': true,
        'dateAcceptationContrat': Timestamp.now(),
        'dateInscription': Timestamp.now(), // Pour calculer les 7 jours
      });

      if (mounted) {
        // Rediriger vers la configuration du PIN (pas la complétion de profil)
        context.go(AppRouter.setupLocalAuth);
      }
    } catch (e) {
      _showError('Erreur lors de l\'acceptation du contrat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Afficher un dialogue de confirmation
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Annuler l\'inscription ?'),
            content: const Text('Vous devez accepter le contrat pour continuer. Voulez-vous vraiment annuler votre inscription ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Non, continuer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRouter.roleSelection);
                },
                child: const Text('Oui, annuler'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.accentRed,
        elevation: 0,
        title: Text(
          'Contrat d\'engagement',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Annuler l\'inscription ?'),
                content: const Text('Vous devez accepter le contrat pour continuer. Voulez-vous vraiment annuler votre inscription ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Non, continuer'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRouter.roleSelection);
                    },
                    child: const Text('Oui, annuler'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Message d'information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.warning.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Veuillez lire attentivement le contrat avant de continuer',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.greyDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu du contrat (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTRAT D\'ENGAGEMENT ARTISAN',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.accentRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Lors de votre inscription, vous devez obligatoirement lire et valider ce contrat d\'engagement.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildArticle(
                    'Article 1',
                    'L\'artisan s\'engage à réaliser les prestations avec sérieux, professionnalisme et dans les délais convenus.',
                  ),

                  _buildArticle(
                    'Article 2',
                    'L\'artisan s\'engage à respecter les tarifs et conditions annoncés sur son profil.',
                  ),

                  _buildArticle(
                    'Article 3',
                    'Tout artisan dont la qualité de travail est jugée insuffisante sera automatiquement retiré de la plateforme sans préavis.',
                  ),

                  _buildArticle(
                    'Article 4',
                    'L\'artisan s\'engage à communiquer uniquement via la messagerie interne pour toute discussion liée à une commande.',
                  ),

                  _buildArticle(
                    'Article 5',
                    'L\'artisan s\'engage à ne pas demander aux clients de payer en dehors du système de paiement officiel.',
                  ),

                  _buildArticle(
                    'Article 6',
                    'Toute fraude ou tentative de contournement entraîne la suspension immédiate et définitive du compte.',
                  ),

                  _buildArticle(
                    'Article 7',
                    'Mon Artisan se réserve le droit de modifier ces conditions avec notification préalable.',
                  ),

                  const SizedBox(height: 32),

                  // Avertissement de retrait automatique
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: AppColors.error, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'RETRAIT AUTOMATIQUE',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tout artisan ayant reçu des réclamations avérées pour travail mal exécuté ou non-respect des engagements sera retiré définitivement de la plateforme.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.greyDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Checkbox et bouton en bas
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Checkbox d'acceptation
                InkWell(
                  onTap: () {
                    setState(() {
                      _hasAccepted = !_hasAccepted;
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _hasAccepted,
                        onChanged: (value) {
                          setState(() {
                            _hasAccepted = value ?? false;
                          });
                        },
                        activeColor: AppColors.accentRed,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'J\'ai lu et j\'accepte les conditions générales et le contrat d\'engagement de la plateforme Mon Artisan. Je comprends que tout manquement à la qualité de mon travail peut entraîner mon retrait automatique et définitif de la plateforme.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.greyDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bouton de validation
                CustomButton(
                  text: 'Finaliser l\'inscription',
                  onPressed: _hasAccepted ? _acceptContract : null,
                  isLoading: _isLoading,
                  backgroundColor: _hasAccepted ? AppColors.accentRed : AppColors.greyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      ), // Fermeture du Scaffold
    ); // Fermeture du PopScope
  }

  Widget _buildArticle(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.accentRed,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.greyDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
