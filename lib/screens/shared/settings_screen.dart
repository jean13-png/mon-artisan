import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              if (user != null && user.hasRole('artisan')) {
                context.go(AppRouter.homeArtisan);
              } else {
                context.go(AppRouter.homeClient);
              }
            }
          },
        ),
        title: Text(
          'Paramètres',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: ListView(
        children: [
          // Section Compte
          _buildSectionHeader('Compte'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Modifier le profil',
            subtitle: 'Nom, prénom, téléphone, etc.',
            onTap: () => context.push(AppRouter.editProfile),
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            subtitle: 'Modifier votre mot de passe',
            onTap: () {
              // TODO: Implémenter changement de mot de passe
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité bientôt disponible'),
                ),
              );
            },
          ),
          
          const Divider(height: 1),
          
          // Section Notifications
          _buildSectionHeader('Notifications'),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Gérer vos notifications',
            onTap: () => context.push(AppRouter.notifications),
          ),
          
          const Divider(height: 1),
          
          // Section Confidentialité
          _buildSectionHeader('Confidentialité et sécurité'),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            subtitle: 'Voir notre politique',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité bientôt disponible'),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            subtitle: 'Lire les conditions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité bientôt disponible'),
                ),
              );
            },
          ),
          
          const Divider(height: 1),
          
          // Section À propos
          _buildSectionHeader('À propos'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'À propos de Mon Artisan',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Mon Artisan',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'assets/images/logo_mon_artisan.png',
                  width: 64,
                  height: 64,
                ),
                children: [
                  const Text(
                    'Trouvez votre artisan en un clic.\n\n'
                    'Connectez clients et artisans au Bénin.',
                  ),
                ],
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Aide et support',
            subtitle: 'Besoin d\'aide ?',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contactez-nous : support@monartisan.bj'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          
          const Divider(height: 1),
          
          // Déconnexion
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Déconnexion',
            subtitle: 'Se déconnecter de l\'application',
            textColor: AppColors.error,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        authProvider.signOut();
                        context.go(AppRouter.roleSelection);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.greyDark,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppColors.primaryBlue,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.greyDark,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.greyMedium,
      ),
      onTap: onTap,
    );
  }
}
