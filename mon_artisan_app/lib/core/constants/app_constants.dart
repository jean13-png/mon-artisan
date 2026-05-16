import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'Mon Artisan';
  static const String appVersion = '1.0.0';
  
  // FedaPay
  static String get fedapayPublicKey => dotenv.env['FEDAPAY_PUBLIC_KEY'] ?? '';
  static String get fedapaySecretKey => dotenv.env['FEDAPAY_SECRET_KEY'] ?? '';
  static String get fedapayApiKey => fedapaySecretKey;
  static String get fedapayBaseUrl => dotenv.env['FEDAPAY_BASE_URL'] ?? 'https://sandbox-api.fedapay.com/v1';
  static const double commissionRate = 0.10; // 10%
  
  // Modes
  static bool get simulateFedaPay => dotenv.env['SIMULATE_FEDAPAY'] == 'true';
  static bool get isTestMode => dotenv.env['APP_TEST_MODE'] == 'true';
  static bool get requirePaymentForArtisan => dotenv.env['REQUIRE_PAYMENT_ARTISAN'] == 'true';
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Images
  static const int maxImageSize = 1048576; // 1MB
  static const int maxPhotosPerCommande = 3;
  
  // Timeouts
  static const int commandeAcceptTimeout = 24; // heures
  static const int commandeValidationTimeout = 48; // heures
  
  // Distances
  static const double defaultSearchRadius = 10.0; // km
  static const double maxSearchRadius = 50.0; // km

  // Tarification diagnostic — CONFIDENTIEL (ne pas afficher en UI)
  /// Calcule les frais de diagnostic selon la distance (formule : 200 FCFA/km + 200 FCFA fixe).
  static double calculerFraisDiagnostic(double distanceKm) {
    return (distanceKm * 200) + 200.0;
  }

  // Séquestre & paiement
  static const int deblocagePaiementDelaiJours = 7; // auto-libération après X jours
}
