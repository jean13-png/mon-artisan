import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/villes_benin.dart';
import '../../core/constants/metiers_data.dart';
import '../../core/routes/app_router.dart';
import '../../core/utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedVille;
  String? _selectedQuartier;
  String? _selectedMetier;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVille == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une ville')),
        );
        return;
      }

      if (widget.role == 'artisan' && _selectedMetier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un métier')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        role: widget.role,
        ville: _selectedVille!,
        quartier: _selectedQuartier ?? '',
        position: const GeoPoint(6.3703, 2.3912), // Cotonou par défaut
      );

      if (success && mounted) {
        // MODE TEST : Sauter le paiement pour les artisans
        // En production, rediriger vers le paiement d'abord
        
        if (widget.role == 'artisan') {
          // Afficher un message en mode test
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MODE TEST : Paiement désactivé. Inscription gratuite.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
          // Rediriger vers le contrat d'engagement
          context.go(AppRouter.contratEngagement);
        } else {
          // Client : configuration du PIN
          context.go(AppRouter.setupLocalAuth);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Erreur lors de l\'inscription'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final allVilles = getAllVilles();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => context.go(AppRouter.roleSelection),
        ),
        title: Text(
          widget.role == 'client' ? 'Inscription Client' : 'Inscription Artisan',
          style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue),
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
                Text(
                  'Créez votre compte',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Remplissez les informations ci-dessous',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),
                
                // Nom
                CustomTextField(
                  label: 'Nom',
                  hint: 'Entrez votre nom',
                  controller: _nomController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                
                // Prénom
                CustomTextField(
                  label: 'Prénom',
                  hint: 'Entrez votre prénom',
                  controller: _prenomController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                
                // Email
                CustomTextField(
                  label: 'Email',
                  hint: 'exemple@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                
                // Téléphone
                CustomTextField(
                  label: 'Téléphone',
                  hint: '+229 XX XX XX XX',
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),
                
                // Ville
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ville',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVille,
                      decoration: InputDecoration(
                        hintText: 'Sélectionnez votre ville',
                        prefixIcon: const Icon(Icons.location_city),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.greyMedium),
                        ),
                      ),
                      items: allVilles.map((ville) {
                        return DropdownMenuItem(
                          value: ville,
                          child: Text(ville),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVille = value;
                          _selectedQuartier = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quartier (optionnel)
                CustomTextField(
                  label: 'Quartier (optionnel)',
                  hint: 'Entrez votre quartier',
                  controller: TextEditingController(text: _selectedQuartier ?? ''),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: 16),
                
                // Métier (si artisan)
                if (widget.role == 'artisan') ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Métier',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMetier,
                        decoration: InputDecoration(
                          hintText: 'Sélectionnez votre métier',
                          prefixIcon: const Icon(Icons.work_outline),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.greyMedium),
                          ),
                        ),
                        items: getAllMetiers().map((metier) {
                          return DropdownMenuItem(
                            value: metier['nom'],
                            child: Text(metier['nom']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedMetier = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Mot de passe
                CustomTextField(
                  label: 'Mot de passe',
                  hint: 'Minimum 6 caractères',
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
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                
                // Confirmation mot de passe
                CustomTextField(
                  label: 'Confirmer le mot de passe',
                  hint: 'Retapez votre mot de passe',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Bouton d'inscription
                CustomButton(
                  text: 'S\'inscrire',
                  onPressed: _handleRegister,
                  isLoading: authProvider.isLoading,
                  backgroundColor: widget.role == 'client' 
                      ? AppColors.primaryBlue 
                      : AppColors.accentRed,
                ),
                const SizedBox(height: 16),
                
                // Lien vers connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte ? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRouter.login),
                      child: Text(
                        'Se connecter',
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
