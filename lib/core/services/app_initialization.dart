import 'package:firebase_core/firebase_core.dart';
import 'package:mon_artisan_app/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'notification_service.dart';

class AppInitialization {
  /// Initialiser l'application
  static Future<void> initialize() async {
    try {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        print('[WARNING] .env error: $e');
      }

      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
      } catch (e) {
        if (!e.toString().contains('duplicate-app')) {
          rethrow;
        }
      }

      try {
        await NotificationService.initialize();
      } catch (e) {
        print('[WARNING] Notifications error: $e');
      }
    } catch (e) {
      print('[ERROR] Initialization error: $e');
      rethrow;
    }
  }
}
