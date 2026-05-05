import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'core/services/app_initialization.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser l'application (Firebase, Notifications, etc.)
  await AppInitialization.initialize();
  
  runApp(const MyApp());
}
