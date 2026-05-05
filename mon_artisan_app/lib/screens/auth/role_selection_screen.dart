import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../widgets/custom_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 25),
            
            // Bannière en haut
            Container(
              width: double.infinity,
              height: 280,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/banner.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppColors.white.withOpacity(0.5),
                      AppColors.white,
                    ],
                    stops: const [0.0, 0.65, 0.85, 1.0],
                  ),
                ),
              ),
            ),
            
            // Contenu principal
            Transform.translate(
              offset: const Offset(0, -55),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo_mon_artisan.png',
                      width: 180,
                      height: 180,
                    ),
                    
                    Transform.translate(
                      offset: const Offset(0, -15),
                      child: Text(
                        'Bienvenue sur Mon Artisan',
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Choisissez votre profil pour continuer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.greyDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    CustomButton(
                      text: 'Je suis un Client',
                      onPressed: () {
                        context.go('${AppRouter.register}?role=client');
                      },
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CustomButton(
                      text: 'Je suis un Artisan',
                      onPressed: () {
                        context.go('${AppRouter.register}?role=artisan');
                      },
                      backgroundColor: AppColors.accentRed,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextButton(
                      onPressed: () {
                        context.go(AppRouter.login);
                      },
                      child: Text(
                        'Déjà inscrit ? Se connecter',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
