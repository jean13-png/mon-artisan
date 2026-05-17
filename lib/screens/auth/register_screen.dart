import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/metiers_data.dart';
import '../../core/routes/app_router.dart';
import '../../core/utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/ville_quartier_selector.dart';
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
  final _promoCodeController = TextEditingController();

  String? _selectedVille;
  String? _selectedQuartier;
  String? _selectedMetier;
  String? _selectedCategorie;

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
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVille == null) {
      _showError('Veuillez sélectionner votre ville');
      return;
    }
    if (_selectedQuartier == null) {
      _showError('Veuillez sélectionner votre quartier');
      return;
    }
    if (widget.role == 'artisan' && _selectedMetier == null) {
      _showError('Veuillez sélectionner votre métier');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Position par défaut selon la ville (sera affinée lors de la complétion du profil)
    final position = _getDefaultPositionForVille(_selectedVille!);

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      role: widget.role,
      ville: _selectedVille!,
      quartier: _selectedQuartier!,
      position: position,
      metier: widget.role == 'artisan' ? _selectedMetier : null,
      metierCategorie: widget.role == 'artisan' ? _selectedCategorie : null,
    );

    // M1 — Enregistrement du code promo si artisan
    if (success && widget.role == 'artisan' && _promoCodeController.text.trim().isNotEmpty) {
      try {
        final userId = authProvider.userModel?.id;
        if (userId != null) {
          await FirebaseFirestore.instance.collection('artisans').doc(userId).update({
            'codePromoUtilise': _promoCodeController.text.trim().toUpperCase(),
          });
        }
      } catch (e) {
        print('[ERROR] Erreur enregistrement code promo: $e');
      }
    }

    if (!mounted) return;

    if (success) {
      if (widget.role == 'artisan') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! Complétez votre profil.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        context.push(AppRouter.contratEngagement);
      } else {
        context.go(AppRouter.homeClient);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erreur lors de l\'inscription'),
          backgroundColor: AppColors.error,
        ),
      );
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

  /// Position GPS approximative par ville (centre de la commune).
  /// Sera affinée par l'utilisateur lors de la complétion du profil.
  GeoPoint _getDefaultPositionForVille(String ville) {
    const Map<String, GeoPoint> positions = {
      'Cotonou': GeoPoint(6.3703, 2.3912),
      'Abomey-Calavi': GeoPoint(6.4489, 2.3559),
      'Porto-Novo': GeoPoint(6.4969, 2.6289),
      'Parakou': GeoPoint(9.3370, 2.6280),
      'Ouidah': GeoPoint(6.3612, 2.0833),
      'Bohicon': GeoPoint(7.1833, 2.0667),
      'Abomey': GeoPoint(7.1833, 1.9833),
      'Natitingou': GeoPoint(10.3167, 1.3833),
      'Djougou': GeoPoint(9.7000, 1.6667),
      'Lokossa': GeoPoint(6.6333, 1.7167),
      'Kandi': GeoPoint(11.1333, 2.9333),
      'Malanville': GeoPoint(11.8667, 3.3833),
      'Savalou': GeoPoint(7.9167, 1.9667),
      'Savè': GeoPoint(8.0333, 2.4833),
      'Pobè': GeoPoint(6.9667, 2.6667),
      'Kétou': GeoPoint(7.3667, 2.6000),
      'Sèmè-Kpodji': GeoPoint(6.3667, 2.5667),
      'Allada': GeoPoint(6.6667, 2.1500),
      'Tanguiéta': GeoPoint(10.6167, 1.2667),
      'Bassila': GeoPoint(9.0000, 1.6667),
    };
    return positions[ville] ?? const GeoPoint(6.3703, 2.3912);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isArtisan = widget.role == 'artisan';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Retourner à la sélection de rôle
          context.go(AppRouter.roleSelection);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go(AppRouter.roleSelection);
              }
            },
          ),
          title: Text(
            isArtisan ? 'Inscription Artisan' : 'Inscription Client',
            style: AppTextStyles.h3.copyWith(color: AppColors.white),
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créez votre compte', style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text(
                  'Tous les champs sont obligatoires',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                ),
                const SizedBox(height: 24),

                // ── Nom ──────────────────────────────────────────────────
                CustomTextField(
                  label: 'Nom *',
                  hint: 'Entrez votre nom de famille',
                  controller: _nomController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),

                // ── Prénom ───────────────────────────────────────────────
                CustomTextField(
                  label: 'Prénom *',
                  hint: 'Entrez votre prénom',
                  controller: _prenomController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),

                // ── Email ────────────────────────────────────────────────
                CustomTextField(
                  label: 'Email *',
                  hint: 'exemple@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // ── Téléphone ────────────────────────────────────────────
                CustomTextField(
                  label: 'Téléphone *',
                  hint: '+229 01 XX XX XX XX',
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),

                // ── Ville + Quartier (widget intelligent) ────────────────
                VilleQuartierSelector(
                  initialVille: _selectedVille,
                  initialQuartier: _selectedQuartier,
                  required: true,
                  onChanged: (ville, quartier) {
                    setState(() {
                      _selectedVille = ville;
                      _selectedQuartier = quartier;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // ── Métier (artisan uniquement) ──────────────────────────
                if (isArtisan) ...[
                  _buildLabel('Métier *'),
                  const SizedBox(height: 8),
                  _MetierAutocomplete(
                    onSelected: (metier, categorie) {
                      setState(() {
                        _selectedMetier = metier;
                        _selectedCategorie = categorie;
                      });
                    },
                    selectedMetier: _selectedMetier,
                  ),
                  if (_selectedCategorie != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined, size: 16, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Catégorie : $_selectedCategorie',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // ── Mot de passe ─────────────────────────────────────────
                CustomTextField(
                  label: 'Mot de passe *',
                  hint: 'Minimum 6 caractères',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                // ── Confirmation mot de passe ────────────────────────────
                CustomTextField(
                  label: 'Confirmer le mot de passe *',
                  hint: 'Retapez votre mot de passe',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Code Promo (artisan uniquement) ──────────────────────
                 if (isArtisan) ...[
                   CustomTextField(
                     label: 'Code Promo (Optionnel)',
                     hint: 'Entrez un code promo si vous en avez un',
                     controller: _promoCodeController,
                     prefixIcon: const Icon(Icons.card_giftcard),
                   ),
                   const SizedBox(height: 16),
                 ],
                const SizedBox(height: 32),

                // ── Bouton inscription ───────────────────────────────────
                CustomButton(
                  text: 'S\'inscrire',
                  onPressed: _handleRegister,
                  isLoading: authProvider.isLoading,
                  backgroundColor: AppColors.primaryBlue,
                ),
                const SizedBox(height: 16),

                // ── Lien connexion ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Déjà un compte ? ', style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.push(AppRouter.login),
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  // ignore: unused_element
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyMedium),
      prefixIcon: Icon(icon, color: AppColors.greyDark),
      filled: true,
      fillColor: AppColors.surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greyMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.greyMedium),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

// ── Widget Autocomplete métier ─────────────────────────────────────────────
class _MetierAutocomplete extends StatefulWidget {
  final void Function(String metier, String categorie) onSelected;
  final String? selectedMetier;

  const _MetierAutocomplete({
    required this.onSelected,
    this.selectedMetier,
  });

  @override
  State<_MetierAutocomplete> createState() => _MetierAutocompleteState();
}

class _MetierAutocompleteState extends State<_MetierAutocomplete> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedMetier != null) {
      _controller.text = widget.selectedMetier!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<Map<String, String>>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text;
            if (query.isEmpty) return getAllMetiers().take(10);
            return searchMetiers(query).take(10);
          },
          displayStringForOption: (option) => option['nom']!,
          onSelected: (option) {
            setState(() => _hasError = false);
            _controller.text = option['nom']!;
            widget.onSelected(option['nom']!, option['categorie']!);
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Ex: Maçon, Électricien, Plombier...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyMedium),
                prefixIcon: const Icon(Icons.work_outline, color: AppColors.greyDark),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clear();
                          setState(() => _hasError = false);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError ? AppColors.error : AppColors.greyMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _hasError ? AppColors.error : AppColors.greyMedium,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  setState(() => _hasError = true);
                  return 'Veuillez saisir votre métier';
                }
                // Vérifier que le métier saisi correspond à un métier connu
                final match = getAllMetiers().any(
                  (m) => m['nom']!.toLowerCase() == value.trim().toLowerCase(),
                );
                if (!match) {
                  setState(() => _hasError = true);
                  return 'Sélectionnez un métier dans la liste';
                }
                setState(() => _hasError = false);
                return null;
              },
              onChanged: (value) {
                // Chercher une correspondance exacte pour auto-sélectionner
                final exact = getAllMetiers().where(
                  (m) => m['nom']!.toLowerCase() == value.trim().toLowerCase(),
                );
                if (exact.isNotEmpty) {
                  widget.onSelected(exact.first['nom']!, exact.first['categorie']!);
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                categoryIcon(option['categorie']!),
                                size: 18,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option['nom']!,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      option['categorie']!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.greyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
