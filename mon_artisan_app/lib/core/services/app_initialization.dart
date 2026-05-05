import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import 'notification_service.dart';

class AppInitialization {
  /// Initialiser l'application
  static Future<void> initialize() async {
    try {
      // Initialiser Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialiser les notifications
      await NotificationService.initialize();

      print('✅ Application initialisée avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }
}
