class AppConstants {
  // App Info
  static const String appName = 'Mon Artisan';
  static const String appVersion = '1.0.0';
  
  // FedaPay - MODE TEST
  // ⚠️ IMPORTANT: Utiliser les clés SANDBOX pour les tests
  static const String fedapayPublicKey = 'pk_sandbox_YOUR_TEST_KEY'; // À remplacer
  static const String fedapaySecretKey = 'sk_sandbox_YOUR_TEST_KEY'; // À remplacer
  static const String fedapayApiKey = fedapaySecretKey;
  static const String fedapayBaseUrl = 'https://sandbox-api.fedapay.com/v1';
  static const double commissionRate = 0.10; // 10%
  
  // ⚠️ MODE SIMULATION: Activer pour tester sans vraie API FedaPay
  static const bool simulateFedaPay = true; // ✅ Mettre à false quand les clés sont bonnes
  
  // Mode test (désactiver le paiement obligatoire)
  static const bool isTestMode = true; // Mettre à false en production
  static const bool requirePaymentForArtisan = false; // Paiement obligatoire artisan (false en test)
  
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
}
