class AppConstants {
  // App Info
  static const String appName = 'Mon Artisan';
  static const String appVersion = '1.0.0';
  
  // FedaPay
  static const String fedapayPublicKey = 'pk_live_IDtylXn9RdMm5EVefFX1ifZt';
  static const String fedapaySecretKey = 'sk_live_3KyG5_jI3QsfFqon1WzIDd8z';
  static const String fedapayApiKey = fedapaySecretKey; // Utiliser la clé secrète pour l'API
  static const String fedapayBaseUrl = 'https://api.fedapay.com/v1';
  static const double commissionRate = 0.10; // 10%
  
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
