import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _tryBiometricLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final canCheck = await BiometricService.isBiometricAvailable();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    
    setState(() {
      _canUseBiometric = canCheck;
      _biometricEnabled = enabled && canCheck;
    });
  }

  Future<void> _tryBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    
    if (!biometricEnabled) return;

    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    
    if (savedEmail == null || savedPassword == null) return;

    final authenticated = await BiometricService.authenticate(
      reason: 'Authentifiez-vous pour accéder à Mon Artisan',
    );

    if (authenticated && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(savedEmail, savedPassword);

      if (success && mounted) {
        final role = authProvider.userModel?.role;
        if (role == 'client') {
          context.go(AppRouter.homeClient);
        } else if (role == 'artisan') {
          context.go(AppRouter.homeArtisan);
        }
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Proposer d'activer la biométrie si disponible et pas encore activée
        if (_canUseBiometric && !_biometricEnabled) {
          _showEnableBiometricDialog();
        } else {
          // Rediriger selon le rôle de l'utilisateur
          final role = authProvider.userModel?.role;
          if (role == 'client') {
            context.go(AppRouter.homeClient);
          } else if (role == 'artisan') {
            context.go(AppRouter.homeArtisan);
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Erreur de connexion'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _showEnableBiometricDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activer l\'authentification biométrique', style: AppTextStyles.h3),
        content: Text(
          'Voulez-vous activer l\'authentification par empreinte digitale ou reconnaissance faciale pour un accès rapide ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Activer'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _enableBiometric();
    } else if (mounted) {
      // Rediriger sans activer la biométrie
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.userModel?.role;
      if (role == 'client') {
        context.go(AppRouter.homeClient);
      } else if (role == 'artisan') {
        context.go(AppRouter.homeArtisan);
      }
    }
  }

  Future<void> _enableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', true);
    await prefs.setString('saved_email', _emailController.text.trim());
    await prefs.setString('saved_password', _passwordController.text);

    setState(() {
      _biometricEnabled = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentification biométrique activée'),
          backgroundColor: AppColors.success,
        ),
      );

      // Rediriger selon le rôle
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.userModel?.role;
      if (role == 'client') {
        context.go(AppRouter.homeClient);
      } else if (role == 'artisan') {
        context.go(AppRouter.homeArtisan);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => context.go(AppRouter.roleSelection),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connexion', style: AppTextStyles.h1),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous pour continuer',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Email ou Téléphone',
                  hint: 'Entrez votre email ou téléphone',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Mot de passe',
                  hint: 'Entrez votre mot de passe',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est requis';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to forgot password
                    },
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomButton(
                      text: 'Se connecter',
                      onPressed: _handleLogin,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                if (_canUseBiometric) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'ou',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.greyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          onPressed: _tryBiometricLogin,
                          icon: const Icon(
                            Icons.fingerprint,
                            size: 48,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        Text(
                          'Connexion biométrique',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.greyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRouter.roleSelection),
                      child: Text(
                        'S\'inscrire',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
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
}
