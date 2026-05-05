import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/villes_benin.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/geolocation_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

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
  List<String> _quartiers = [];
  File? _imageFile;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

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
      
      if (_selectedVille != null) {
        _loadQuartiers(_selectedVille!);
      }
    }
  }

  void _loadQuartiers(String ville) {
    setState(() {
      _quartiers = villesBenin[ville] ?? [];
    });
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

  Future<void> _updateLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      final position = await GeolocationService.getCurrentGeoPoint();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localisation mise à jour'),
            backgroundColor: AppColors.success,
          ),
        );
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
      setState(() => _isLoadingLocation = false);
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
        photoUrl = await FirebaseService.uploadProfilePhoto(userId, _imageFile!);
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
          ),
        );
        Navigator.pop(context);
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
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final role = authProvider.userModel?.role;
            if (role == 'client') {
              context.go(AppRouter.homeClient);
            } else {
              context.go(AppRouter.homeArtisan);
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

                    DropdownButtonFormField<String>(
                      value: _selectedVille,
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: villesBenin.keys.map((ville) {
                        return DropdownMenuItem(
                          value: ville,
                          child: Text(ville),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVille = value;
                          _selectedQuartier = null;
                          if (value != null) {
                            _loadQuartiers(value);
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _quartiers.contains(_selectedQuartier) ? _selectedQuartier : null,
                      decoration: InputDecoration(
                        labelText: 'Quartier',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _quartiers.isEmpty 
                        ? [const DropdownMenuItem(value: null, child: Text('Sélectionnez d\'abord une ville'))]
                        : _quartiers.map((quartier) {
                            return DropdownMenuItem(
                              value: quartier,
                              child: Text(quartier),
                            );
                          }).toList(),
                      onChanged: _quartiers.isEmpty ? null : (value) {
                        setState(() {
                          _selectedQuartier = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _isLoadingLocation ? null : _updateLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isLoadingLocation
                          ? 'Mise à jour...'
                          : 'Mettre à jour ma position'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primaryBlue),
                      ),
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
