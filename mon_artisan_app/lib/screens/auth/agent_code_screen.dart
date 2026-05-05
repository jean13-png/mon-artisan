import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';

class AgentCodeScreen extends StatefulWidget {
  const AgentCodeScreen({super.key});

  @override
  State<AgentCodeScreen> createState() => _AgentCodeScreenState();
}

class _AgentCodeScreenState extends State<AgentCodeScreen> {
  final _codeController = TextEditingController();
  bool _skipAgent = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _continueToRegister() {
    final code = _codeController.text.trim().toUpperCase();
    
    // Rediriger vers l'inscription avec le code agent (ou vide si skip)
    context.go('${AppRouter.register}?role=artisan&codeAgent=$code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go(AppRouter.roleSelection),
        ),
        title: Text(
          'Code agent',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icône
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              'Inscription via agent terrain',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Avez-vous été contacté par un agent terrain Mon Artisan ?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.greyDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Checkbox "Je n'ai pas d'agent"
            CheckboxListTile(
              value: _skipAgent,
              onChanged: (value) {
                setState(() {
                  _skipAgent = value ?? false;
                  if (_skipAgent) {
                    _codeController.clear();
                  }
                });
              },
              title: Text(
                'Je n\'ai pas été contacté par un agent',
                style: AppTextStyles.bodyMedium,
              ),
              activeColor: AppColors.primaryBlue,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),

            // Champ code agent (désactivé si skip)
            if (!_skipAgent) ...[
              Text(
                'Code de l\'agent',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: 'Ex: AGENT001',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le code agent vous permet de bénéficier d\'un accompagnement personnalisé et d\'un support prioritaire.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Bouton continuer
            ElevatedButton(
              onPressed: _continueToRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continuer',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            Text(
              'Vous pourrez payer les frais d\'inscription (958 FCFA) après avoir rempli vos informations.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.greyDark,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

