import 'package:flutter/material.dart';

/// Palette officielle Mon Artisan — thème clair (charte graphique).
class AppColors {
  static const Color primaryBlue = Color(0xFF1A3C6E);
  static const Color accentRed = Color(0xFFC0392B);
  static const Color white = Color(0xFFFFFFFF);

  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyMedium = Color(0xFFBDBDBD);
  static const Color greyDark = Color(0xFF757575);
  static const Color black = Color(0xFF000000);

  /// Fond général (liste / scaffold) — léger gris pour détacher les cartes blanches.
  static const Color surface = Color(0xFFF5F5F5);

  /// Cartes, champs remplis, surfaces surélevées.
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Texte principal (contraste élevé sur fond clair).
  static const Color onSurface = Color(0xFF1C1C1E);

  /// Texte secondaire — suffisamment sombre pour rester lisible sur gris/blanc (WCAG).
  static const Color onSurfaceMuted = Color(0xFF3C3C41);

  // États
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFC0392B);
  static const Color info = Color(0xFF1A3C6E);

  static const Color overlay = Color(0x80000000);
}
