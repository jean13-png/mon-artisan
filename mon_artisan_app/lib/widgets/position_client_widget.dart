import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/services/adresse_service.dart';
import '../core/services/firebase_service.dart';

/// Carte affichée avant une commande pour proposer au client
/// de mettre à jour sa position.
///
/// - Si la permission est déjà accordée : détecte et affiche l'adresse directement.
/// - Sinon : demande la permission puis détecte.
/// - Affiche l'adresse en langage clair (pas de coordonnées brutes).
class PositionClientWidget extends StatefulWidget {
  final String userId;

  /// Appelé quand la position est mise à jour avec succès.
  final void Function(AdresseDetectee adresse)? onPositionMiseAJour;

  const PositionClientWidget({
    super.key,
    required this.userId,
    this.onPositionMiseAJour,
  });

  @override
  State<PositionClientWidget> createState() => _PositionClientWidgetState();
}

class _PositionClientWidgetState extends State<PositionClientWidget> {
  _Etat _etat = _Etat.initial;
  AdresseDetectee? _adresse;
  String? _erreur;

  Future<void> _detecterPosition() async {
    setState(() {
      _etat = _Etat.chargement;
      _erreur = null;
    });

    try {
      final adresse = await AdresseService.detecterPosition();

      // Sauvegarder dans Firestore
      await FirebaseService.firestore
          .collection('users')
          .doc(widget.userId)
          .update({
        'position': adresse.position,
        'quartier': adresse.quartier.isNotEmpty
            ? adresse.quartier
            : null,
        'ville': adresse.ville.isNotEmpty ? adresse.ville : null,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        setState(() {
          _adresse = adresse;
          _etat = _Etat.succes;
        });
        widget.onPositionMiseAJour?.call(adresse);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e.toString().replaceAll('Exception: ', '');
          _etat = _Etat.erreur;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _etat == _Etat.succes
              ? AppColors.success.withOpacity(0.4)
              : AppColors.primaryBlue.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContenu(),
      ),
    );
  }

  Widget _buildContenu() {
    switch (_etat) {
      case _Etat.initial:
        return _buildInitial();
      case _Etat.chargement:
        return _buildChargement();
      case _Etat.succes:
        return _buildSucces();
      case _Etat.erreur:
        return _buildErreur();
    }
  }

  Widget _buildInitial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location,
                  color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Où êtes-vous ?',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Partagez votre position pour que l\'artisan vous trouve facilement.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.greyDark),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _detecterPosition,
            icon: const Icon(Icons.gps_fixed, size: 18),
            label: const Text('Détecter ma position automatiquement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChargement() {
    return Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détection en cours...',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Nous cherchons votre adresse exacte.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.greyDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSucces() {
    final adresse = _adresse!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Position détectée',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
            // Bouton pour re-détecter
            TextButton(
              onPressed: _detecterPosition,
              child: Text(
                'Actualiser',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place, color: AppColors.accentRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adresse.adresseComplete,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (adresse.quartier.isNotEmpty ||
                        adresse.ville.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (adresse.quartier.isNotEmpty)
                            adresse.quartier,
                          if (adresse.ville.isNotEmpty) adresse.ville,
                        ].join(' — '),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.greyDark),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErreur() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Position non disponible',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _erreur ?? 'Une erreur est survenue.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _detecterPosition,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                onPressed: () {
                  // Ignorer et continuer sans position
                  setState(() => _etat = _Etat.initial);
                },
                child: Text(
                  'Continuer sans',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.greyDark),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _Etat { initial, chargement, succes, erreur }
