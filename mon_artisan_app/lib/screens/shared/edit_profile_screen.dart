import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/ville_quartier_selector.dart';
import '../../widgets/position_client_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _selectedVille;
  String? _selectedQuartier;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user != null) {
      _nomController.text = user.nom;
      _prenomController.text = user.prenom;
      _telephoneController.text = user.telephone;
      _emailController.text = user.email;
      _selectedVille = user.ville;
      _selectedQuartier = user.quartier;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVille == null || _selectedQuartier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une ville et un quartier'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel!.id;

      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await CloudinaryService.uploadImage(
          _imageFile!.path,
          'users/$userId/profile',
        );
      }

      final updates = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'email': _emailController.text.trim(),
        'ville': _selectedVille,
        'quartier': _selectedQuartier,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

      await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .update(updates);

      // Si c'est un artisan, mettre à jour aussi sa collection dénormalisée
      if (authProvider.userModel!.isArtisan) {
        final artisanUpdates = {
          'nom': updates['nom'],
          'prenom': updates['prenom'],
          if (photoUrl != null) 'photoUrl': photoUrl,
          'updatedAt': Timestamp.now(),
        };
        
        final artisanQuery = await FirebaseService.firestore
            .collection('artisans')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
            
        if (artisanQuery.docs.isNotEmpty) {
          await artisanQuery.docs.first.reference.update(artisanUpdates);
        }
      }

      // Recharger les données utilisateur
      final updatedUser = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (updatedUser.exists) {
        await authProvider.setUserFromFirestore(updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Retour à l'écran précédent ou dashboard
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          final updatedUser = authProvider.userModel;
          if (updatedUser != null && updatedUser.hasRole('artisan')) {
            context.go(AppRouter.homeArtisan);
          } else {
            context.go(AppRouter.homeClient);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Chargement...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.userModel?.hasRole('artisan') == true) {
                context.go(AppRouter.homeArtisan);
              } else {
                context.go(AppRouter.homeClient);
              }
            }
          },
        ),
        title: Text(
          'Modifier le profil',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Enregistrement...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Photo de profil (seulement pour les artisans)
                    if (user.isArtisan)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : user.photoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(user.photoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: _imageFile == null && user.photoUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.primaryBlue,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Avatar par défaut pour les clients (non modifiable)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    if (user.isArtisan)
                      Text(
                        'Appuyez pour changer la photo',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.greyDark,
                        ),
                      )
                    else
                      Text(
                        '${user.prenom} ${user.nom}',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    
                    const SizedBox(height: 32),

                    TextField(
                      controller: _nomController,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _prenomController,
                      decoration: InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _telephoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // ── Ville + Quartier intelligent ──────────────────────
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

                    // ── Mise à jour de position GPS ───────────────────────
                    PositionClientWidget(
                      userId: Provider.of<AuthProvider>(context, listen: false).userModel!.id,
                      onPositionMiseAJour: (adresse) {
                        // Mettre à jour ville/quartier si détectés
                        if (adresse.ville.isNotEmpty) {
                          setState(() {
                            _selectedVille = adresse.ville;
                            _selectedQuartier = adresse.quartier.isNotEmpty
                                ? adresse.quartier
                                : _selectedQuartier;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Enregistrer',
                      onPressed: _saveProfile,
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
