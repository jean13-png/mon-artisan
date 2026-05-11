import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../widgets/map_picker_widget.dart';

/// Écran plein écran de sélection / confirmation de position.
///
/// Retourne un [MapPosition] si l'utilisateur confirme,
/// ou null s'il annule.
class LocationPickerScreen extends StatefulWidget {
  /// Titre affiché dans l'AppBar
  final String titre;

  /// Texte du bouton de confirmation
  final String labelBoutonConfirm;

  /// Position initiale connue (optionnel)
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.titre = 'Confirmer votre position',
    this.labelBoutonConfirm = 'Confirmer cette position',
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MapPosition? _positionSelectionnee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context, null),
          tooltip: 'Annuler',
        ),
        title: Text(
          widget.titre,
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        actions: [
          // Indicateur "gratuit, aucune clé API"
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public, color: AppColors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'OpenStreetMap',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Instruction ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryBlue.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Appuyez sur la carte pour déplacer le marqueur et ajuster votre position exacte.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),

          // ── Carte ───────────────────────────────────────────────
          Expanded(
            child: MapPickerWidget(
              initialLatitude: widget.initialLatitude,
              initialLongitude: widget.initialLongitude,
              showCenterButton: true,
              onPositionChanged: (pos) {
                setState(() => _positionSelectionnee = pos);
              },
            ),
          ),

          // ── Résumé position + Bouton Confirmer ──────────────────
          _buildPanneauConfirmation(),
        ],
      ),
    );
  }

  Widget _buildPanneauConfirmation() {
    final pos = _positionSelectionnee;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé adresse
            if (pos != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place,
                      color: AppColors.accentRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pos.adresseComplete,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (pos.quartier.isNotEmpty || pos.ville.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _construirePhrase(pos),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.greyDark),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                'Détection de la position en cours...',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.greyDark),
              ),
              const SizedBox(height: 12),
            ],

            // Bouton confirmer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pos != null
                    ? () => Navigator.pop(context, pos)
                    : null,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(widget.labelBoutonConfirm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.greyMedium,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une phrase lisible : "Vous êtes à Zogbadjè, devant la rue du marché"
  String _construirePhrase(MapPosition pos) {
    final parts = <String>[];
    if (pos.quartier.isNotEmpty) parts.add(pos.quartier);
    if (pos.rue.isNotEmpty) parts.add('devant ${pos.rue}');
    if (pos.ville.isNotEmpty && pos.ville != pos.quartier) {
      parts.add(pos.ville);
    }
    if (parts.isEmpty) return '';
    return 'Vous êtes à ${parts.join(', ')}';
  }
}
