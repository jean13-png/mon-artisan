import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/local_auth_service.dart';
import '../../providers/auth_provider.dart';

class VerifyLocalAuthScreen extends StatefulWidget {
  const VerifyLocalAuthScreen({super.key});

  @override
  State<VerifyLocalAuthScreen> createState() => _VerifyLocalAuthScreenState();
}

class _VerifyLocalAuthScreenState extends State<VerifyLocalAuthScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _canUseBiometric = false;
  String _pin = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAndTryAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAndTryAuth() async {
    final biometricEnabled = await LocalAuthService.isBiometricEnabled();
    final canUse = await LocalAuthService.canUseBiometric();
    
    setState(() {
      _canUseBiometric = biometricEnabled && canUse;
    });

    // Essayer automatiquement la biométrie si activée
    if (_canUseBiometric && mounted) {
      await _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final success = await LocalAuthService.authenticateWithBiometric();
    
    if (success && mounted) {
      _navigateToDashboard();
    }
  }

  void _onPinInput(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
      });

      // Vérifier automatiquement quand 6 chiffres sont entrés
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onPinDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    final isValid = await LocalAuthService.verifyPinCode(_pin);

    if (isValid && mounted) {
      _navigateToDashboard();
    } else {
      setState(() {
        _pin = '';
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN incorrect'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.userModel?.role;
    
    if (role == 'client') {
      context.go(AppRouter.homeClient);
    } else {
      context.go(AppRouter.homeArtisan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo_mon_artisan.png',
                  width: 120,
                  height: 120,
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Bienvenue',
                  style: AppTextStyles.h1.copyWith(color: AppColors.white),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Entrez votre code PIN',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Affichage du PIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _pin.length
                            ? AppColors.white
                            : AppColors.white.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 48),
                
                // Clavier numérique
                _buildNumericKeypad(),
                
                const SizedBox(height: 32),
                
                // Bouton empreinte
                if (_canUseBiometric)
                  Column(
                    children: [
                      Text(
                        'ou',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        onPressed: _authenticateWithBiometric,
                        icon: const Icon(
                          Icons.fingerprint,
                          size: 48,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Utiliser l\'empreinte',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildKeypadRow(['', '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) {
        if (digit.isEmpty) {
          return const SizedBox(width: 70, height: 70);
        }
        
        if (digit == 'delete') {
          return InkWell(
            onTap: _onPinDelete,
            borderRadius: BorderRadius.circular(35),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.backspace_outlined,
                color: AppColors.white,
                size: 24,
              ),
            ),
          );
        }
        
        return InkWell(
          onTap: () => _onPinInput(digit),
          borderRadius: BorderRadius.circular(35),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                digit,
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.white,
                  fontSize: 28,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
