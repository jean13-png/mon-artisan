import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Timer strict de 2 secondes
    Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Attendre que l'initialisation de l'auth soit terminée si elle est encore en cours
    if (!authProvider.isInitialCheckDone) {
      debugPrint('[SPLASH] Attente de l\'initialisation de l\'auth...');
      // On peut soit attendre ici, soit laisser le redirect de GoRouter s'en charger
      // puisque AuthProvider notifiera quand isInitialCheckDone changera.
      // Mais pour la sécurité du timer, on va attendre un peu.
      int attempts = 0;
      while (!authProvider.isInitialCheckDone && attempts < 30) { // Max 3 secondes de plus
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      final user = authProvider.userModel!;
      debugPrint('[SPLASH] Authentifié, redirection vers le compte');
      
      if (user.hasRole('admin')) {
        context.go(AppRouter.adminDashboard);
      } else if (user.hasRole('artisan')) {
        context.go(AppRouter.homeArtisan);
      } else {
        context.go(AppRouter.homeClient);
      }
    } else {
      debugPrint('[SPLASH] Non authentifié ou userModel manquant, redirection vers roleSelection');
      context.go(AppRouter.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3C6E), // Bleu uni identité
      body: Stack(
        children: [
          // Logo centré
          Center(
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback si l'image n'est pas encore là
                  return const Icon(Icons.handyman, size: 80, color: Colors.white);
                },
              ),
            ),
          ),
          
          // Chargement et Version en bas
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Version 1.0',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
