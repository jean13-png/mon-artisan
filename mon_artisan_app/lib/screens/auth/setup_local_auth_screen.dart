import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/local_auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class SetupLocalAuthScreen extends StatefulWidget {
  const SetupLocalAuthScreen({super.key});

  @override
  State<SetupLocalAuthScreen> createState() => _SetupLocalAuthScreenState();
}

class _SetupLocalAuthScreenState extends State<SetupLocalAuthScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _canUseBiometric = false;
  bool _enableBiometric = false;
  bool _isLoading = false;
  int _step = 1; // 1: PIN, 2: Biométrie

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final canUse = await LocalAuthService.canUseBiometric();
    setState(() {
      _canUseBiometric = canUse;
    });
  }

  Future<void> _setupPin() async {
    if (_pinController.text.length != 6) {
      _showError('Le code PIN doit contenir 6 chiffres');
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      _showError('Les codes PIN ne correspondent pas');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(_pinController.text)) {
      _showError('Le code PIN doit contenir uniquement des chiffres');
      return;
    }

    // Passer à l'étape biométrie si disponible
    if (_canUseBiometric) {
      setState(() {
        _step = 2;
      });
    } else {
      await _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id;

      if (userId == null) {
        _showError('Erreur: utilisateur non connecté');
        return;
      }

      await LocalAuthService.setupLocalAuth(
        pin: _pinController.text,
        enableBiometric: _enableBiometric,
        userId: userId,
      );

      if (mounted) {
        // Rediriger vers le dashboard approprié
        final role = authProvider.userModel?.role;
        if (role == 'client') {
          context.go(AppRouter.homeClient);
        } else {
          context.go(AppRouter.homeArtisan);
        }
      }
    } catch (e) {
      _showError('Erreur lors de la configuration: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'Configuration de sécurité',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _step == 1 ? _buildPinStep() : _buildBiometricStep(),
        ),
      ),
    );
  }

  Widget _buildPinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Icon(
            Icons.lock_outline,
            size: 80,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Créez votre code PIN',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Pour simplifier votre accès, définissez un code PIN de 6 chiffres',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.greyDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(letterSpacing: 16),
          decoration: InputDecoration(
            labelText: 'Code PIN',
            hintText: '• • • • • •',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _confirmPinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(letterSpacing: 16),
          decoration: InputDecoration(
            labelText: 'Confirmer le code PIN',
            hintText: '• • • • • •',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 48),
        CustomButton(
          text: _canUseBiometric ? 'Suivant' : 'Terminer',
          onPressed: _setupPin,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildBiometricStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Icon(
            Icons.fingerprint,
            size: 80,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Activer l\'empreinte digitale',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Utilisez votre empreinte digitale pour un accès encore plus rapide',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.greyDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.fingerprint,
                size: 40,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empreinte digitale',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connexion rapide et sécurisée',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.greyDark,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enableBiometric,
                onChanged: (value) {
                  setState(() {
                    _enableBiometric = value;
                  });
                },
                activeColor: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        CustomButton(
          text: 'Terminer',
          onPressed: _finishSetup,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _step = 1;
              });
            },
            child: Text(
              'Retour',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
