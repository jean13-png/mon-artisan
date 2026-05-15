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
  /// Durée minimale d'affichage du splash (animation).
  static const _kMinSplashDuration = Duration(milliseconds: 500);

  /// Timeout maximal pour que Firestore charge le userModel.
  static const _kUserModelTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Lancer l'animation du splash ET l'attente du userModel en parallèle.
    // On attend que LES DEUX soient terminés avant de naviguer.
    await Future.wait([
      _waitForUserModel(authProvider),
      Future.delayed(_kMinSplashDuration),
    ]);

    if (!mounted) return;
    _redirect(authProvider);
  }

  /// Attend de façon réactive que [authProvider.userModel] soit chargé.
  ///
  /// - Si l'utilisateur n'est pas authentifié, résout immédiatement.
  /// - Si [userModel] est déjà disponible, résout immédiatement.
  /// - Sinon, écoute les changements du provider jusqu'à ce que [userModel]
  ///   soit non-null OU que le [_kUserModelTimeout] soit atteint.
  Future<void> _waitForUserModel(AuthProvider authProvider) async {
    // Pas d'utilisateur Firebase → rien à attendre.
    if (authProvider.firebaseUser == null) return;

    // userModel déjà chargé (Auth + Firestore rapides) → résout immédiatement.
    if (authProvider.userModel != null) return;

    final completer = Completer<void>();

    void listener() {
      // userModel chargé ou utilisateur déconnecté entre-temps.
      if (authProvider.userModel != null || authProvider.firebaseUser == null) {
        if (!completer.isCompleted) completer.complete();
      }
    }

    authProvider.addListener(listener);

    try {
      // Race entre la résolution du completer et le timeout.
      await completer.future.timeout(
        _kUserModelTimeout,
        onTimeout: () {
          // Timeout dépassé : on continue quand même.
          // _redirect() gérera l'état (userModel toujours null → roleSelection).
          print('[SPLASH] Timeout: userModel non chargé après ${_kUserModelTimeout.inSeconds}s — réseau lent ?');
        },
      );
    } finally {
      authProvider.removeListener(listener);
    }
  }

  /// Choisit la route de destination selon l'état d'authentification.
  void _redirect(AuthProvider authProvider) {
    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      final user = authProvider.userModel!;

      print('[AUTH] User authenticated: ${user.email}');
      print('[AUTH] User roles: ${user.roles}');
      print('[AUTH] Has admin role: ${user.hasRole("admin")}');

      if (user.hasRole('admin')) {
        print('[REDIRECT] Redirecting to admin dashboard');
        context.go(AppRouter.adminDashboard);
        return;
      }

      _navigateToRoleDashboard();
    } else {
      // userModel null après timeout = réseau trop lent ou utilisateur non inscrit.
      // On redirige vers la sélection de rôle (l'utilisateur sera invité à se reconnecter).
      print('[AUTH] User not authenticated or userModel unavailable → roleSelection');
      context.go(AppRouter.roleSelection);
    }
  }

  void _navigateToRoleDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    
    if (user == null) return;
    
    // Vérifier si c'est un admin
    if (user.hasRole('admin')) {
      context.go(AppRouter.adminDashboard);
      return;
    }
    
    // Si l'utilisateur a plusieurs rôles, lui demander de choisir
    if (user.roles.length > 1) {
      _showRoleSelectionDialog(user.roles);
    } else {
      // Rediriger selon le rôle unique
      final role = user.roles.first;
      if (role == 'client') {
        context.go(AppRouter.homeClient);
      } else {
        context.go(AppRouter.homeArtisan);
      }
    }
  }

  void _showRoleSelectionDialog(List<String> roles) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Choisissez votre profil', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous avez plusieurs profils. Lequel souhaitez-vous utiliser ?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (roles.contains('admin'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRouter.adminDashboard);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.admin_panel_settings, color: AppColors.white),
                      const SizedBox(width: 8),
                      Text('Administrateur', style: AppTextStyles.button),
                    ],
                  ),
                ),
              ),
            if (roles.contains('admin') && (roles.contains('client') || roles.contains('artisan')))
              const SizedBox(height: 12),
            if (roles.contains('client'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRouter.homeClient);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Client', style: AppTextStyles.button),
                ),
              ),
            if (roles.contains('client') && roles.contains('artisan'))
              const SizedBox(height: 12),
            if (roles.contains('artisan'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRouter.homeArtisan);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Artisan', style: AppTextStyles.button),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo_mon_artisan.png',
                width: 200,
                height: 200,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'V1.0',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
