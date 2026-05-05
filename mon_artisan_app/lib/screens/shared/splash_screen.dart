import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/local_auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../scripts/create_admin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated && authProvider.userModel != null) {
        // Utilisateur connecté - vérifier si l'auth locale est configurée
        final isAuthConfigured = await LocalAuthService.isAuthConfigured();
        
        if (isAuthConfigured) {
          // Auth locale configurée - demander vérification
          context.go(AppRouter.verifyLocalAuth);
        } else {
          // Auth locale non configurée - proposer la configuration
          _showSetupAuthDialog();
        }
      } else {
        // Utilisateur non connecté, aller à la sélection de rôle
        context.go(AppRouter.roleSelection);
      }
    }
  }

  void _showSetupAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Sécuriser votre compte', style: AppTextStyles.h3),
        content: Text(
          'Configurez un code PIN et votre empreinte digitale pour un accès rapide et sécurisé',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToRoleDashboard();
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRouter.setupLocalAuth);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Configurer'),
          ),
        ],
      ),
    );
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
                    backgroundColor: AppColors.accentRed,
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
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_mon_artisan.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              'Mon Artisan',
              style: AppTextStyles.h1.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Trouvez votre artisan en un clic',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
            const SizedBox(height: 48),
            // BOUTON TEMPORAIRE POUR CRÉER LE COMPTE ADMIN
            // ⚠️ À SUPPRIMER APRÈS CRÉATION DU COMPTE
            ElevatedButton(
              onPressed: () async {
                await createAdminAccount();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compte admin créé ! Vérifiez les logs.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '🔧 CRÉER COMPTE ADMIN',
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
