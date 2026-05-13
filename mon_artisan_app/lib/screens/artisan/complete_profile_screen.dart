import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/metiers_data.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/ville_quartier_selector.dart';
import '../../widgets/position_client_widget.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cipController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _diplomeUrl;
  String? _cipPhotoUrl; // Nouvelle variable pour la photo de la carte CIP
  final List<String> _atelierPhotosUrls = [];
  bool _isLoading = false;
  bool _isUploadingDiplome = false;
  bool _isUploadingCipPhoto = false;
  bool _isUploadingPhotos = false;
  
  // Métier sélectionné
  String? _selectedMetier;
  String? _selectedCategorie;

  // Localisation
  String? _selectedVille;
  String? _selectedQuartier;
  Position? _currentPosition;

  @override
  void dispose() {
    _cipController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDiplome() async {
    setState(() => _isUploadingDiplome = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);

      print('[UPLOAD] Upload diplôme depuis: ${image.path}');
      print('[INFO] User ID: ${authProvider.userModel!.id}');

      final storagePath =
          'artisans/${authProvider.userModel!.id}/diplome/${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('[INFO] Chemin Storage: $storagePath');

      final url = await artisanProvider.uploadImage(
        image.path,
        storagePath,
      );

      if (!mounted) return;
      print('[SUCCESS] Diplôme uploadé: $url');

      setState(() {
        _diplomeUrl = url;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text('Diplôme téléchargé avec succès'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Erreur upload diplôme: $e');
      if (mounted) {
        _showError('Impossible de télécharger le diplôme. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingDiplome = false);
      }
    }
  }

  Future<void> _pickCipPhoto() async {
    setState(() => _isUploadingCipPhoto = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);

      print('[UPLOAD] Upload carte CIP depuis: ${image.path}');
      print('[INFO] User ID: ${authProvider.userModel!.id}');

      final storagePath =
          'artisans/${authProvider.userModel!.id}/cip/${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('[INFO] Chemin Storage: $storagePath');

      final url = await artisanProvider.uploadImage(
        image.path,
        storagePath,
      );

      if (!mounted) return;
      print('[SUCCESS] Carte CIP uploadée: $url');

      setState(() {
        _cipPhotoUrl = url;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text('Carte CIP téléchargée avec succès'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Erreur upload carte CIP: $e');
      if (mounted) {
        _showError('Impossible de télécharger la carte CIP. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCipPhoto = false);
      }
    }
  }

  Future<void> _pickAtelierPhotos() async {
    if (_atelierPhotosUrls.length >= 5) {
      _showError('Maximum 5 photos');
      return;
    }

    setState(() => _isUploadingPhotos = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isEmpty) return;
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);

      print('[UPLOAD] Upload de ${images.length} photo(s)');
      print('[INFO] User ID: ${authProvider.userModel!.id}');

      int uploaded = 0;
      for (final image in images.take(5 - _atelierPhotosUrls.length)) {
        final storagePath =
            'artisans/${authProvider.userModel!.id}/atelier/${DateTime.now().millisecondsSinceEpoch}_$uploaded.jpg';
        print('[INFO] Upload photo ${uploaded + 1}: $storagePath');

        final url = await artisanProvider.uploadImage(
          image.path,
          storagePath,
        );

        if (!mounted) break;
        print('[SUCCESS] Photo ${uploaded + 1} uploadée: $url');

        setState(() {
          _atelierPhotosUrls.add(url);
        });

        uploaded++;
      }

      if (mounted && uploaded > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.white),
                const SizedBox(width: 8),
                Text('$uploaded photo(s) téléchargée(s)'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Erreur upload photos: $e');
      if (mounted) {
        _showError('Impossible de télécharger les photos. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhotos = false);
      }
    }
  }

  void _removeAtelierPhoto(int index) {
    setState(() {
      _atelierPhotosUrls.removeAt(index);
    });
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCategorie == null || _selectedMetier == null) {
      _showError('Choisissez votre catégorie et votre métier');
      return;
    }
    
    if (_selectedVille == null) {
      _showError('Choisissez votre ville');
      return;
    }
    
    if (_selectedQuartier == null) {
      _showError('Choisissez votre quartier');
      return;
    }

    if (_diplomeUrl == null) {
      _showError('Ajoutez votre diplôme ou certificat');
      return;
    }

    if (_cipPhotoUrl == null) {
      _showError('Ajoutez la photo de votre carte CIP');
      return;
    }

    if (_atelierPhotosUrls.isEmpty) {
      _showError('Ajoutez au moins 1 photo de votre matériel');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      
      print('[SUBMIT] Soumission du profil...');
      print('[INFO] User ID: ${authProvider.userModel!.id}');
      print('[INFO] Ville: $_selectedVille, Quartier: $_selectedQuartier');
      print('[INFO] Diplôme: $_diplomeUrl');
      print('[INFO] Photos: ${_atelierPhotosUrls.length}');
      
      // Construire l'adresse simple
      final adresse = '$_selectedQuartier, $_selectedVille';
      
      final success = await artisanProvider.completeArtisanProfile(
        userId: authProvider.userModel!.id,
        metier: _selectedMetier!,
        metierCategorie: _selectedCategorie!,
        cip: _cipController.text.trim(),
        cipPhoto: _cipPhotoUrl!,
        diplome: _diplomeUrl!,
        atelierPhotos: _atelierPhotosUrls,
        atelierAdresse: adresse,
        description: _descriptionController.text.trim(),
        ville: _selectedVille!,
        quartier: _selectedQuartier!,
        position: _currentPosition,
      );

      if (success && mounted) {
        print('[SUCCESS] Profil soumis avec succès');
        _showSuccess();
      } else if (mounted) {
        print('[ERROR] Échec soumission: ${artisanProvider.errorMessage}');
        _showError(artisanProvider.errorMessage ?? 'Erreur. Réessayez.');
      }
    } catch (e) {
      print('[ERROR] Erreur soumission: $e');
      if (mounted) {
        _showError('Erreur. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Profil envoyé !', style: AppTextStyles.h3),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre profil a été envoyé avec succès.',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.greyDark, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vérification: 24-48 heures',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.notifications_active, color: AppColors.greyDark, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous recevrez une notification',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // ferme le dialog
              // Retour au home artisan (remplace toute la pile)
              context.go(AppRouter.homeArtisan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Retour vers le dashboard artisan
        context.go(AppRouter.homeArtisan);
      },
      child: Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.accentRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Compléter mon profil',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
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
                // Message d'information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complétez ces informations pour activer votre profil. Vérification sous 24-48h.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.greyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Informations pré-remplies
                Text('Informations de base', style: AppTextStyles.h3),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Nom complet',
                  controller: TextEditingController(text: user?.fullName ?? ''),
                  enabled: false,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Téléphone',
                  controller: TextEditingController(text: user?.telephone ?? ''),
                  enabled: false,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Email',
                  controller: TextEditingController(text: user?.email ?? ''),
                  enabled: false,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                
                const SizedBox(height: 32),
                
                // Informations professionnelles
                Text('Informations professionnelles', style: AppTextStyles.h3),
                const SizedBox(height: 16),

                // Dropdown Catégorie — liste complète depuis metiersData
                DropdownButtonFormField<String>(
                  value: _selectedCategorie,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Catégorie *',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: metiersData.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategorie = value;
                      _selectedMetier = null;
                    });
                  },
                  validator: (v) =>
                      v == null ? 'Choisissez une catégorie' : null,
                ),

                const SizedBox(height: 16),

                // Dropdown Métier — lié à la catégorie
                DropdownButtonFormField<String>(
                  value: _selectedMetier,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Métier *',
                    prefixIcon: const Icon(Icons.work_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _selectedCategorie == null
                      ? [const DropdownMenuItem(
                          value: null,
                          child: Text('Choisissez d\'abord une catégorie'))]
                      : (metiersData[_selectedCategorie] ?? [])
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m),
                              ))
                          .toList(),
                  onChanged: _selectedCategorie == null
                      ? null
                      : (v) => setState(() => _selectedMetier = v),
                  validator: (v) =>
                      v == null ? 'Choisissez votre métier' : null,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Numéro CIP (Carte d\'Identité Professionnelle)',
                  hint: 'Ex: CIP123456789',
                  controller: _cipController,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entrez votre numéro CIP';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Photo de la carte CIP
                Text(
                  'Photo de la carte CIP',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Photo claire de votre Carte d\'Identité Professionnelle',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                ),
                const SizedBox(height: 12),
                
                if (_cipPhotoUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greyMedium),
                      image: DecorationImage(
                        image: NetworkImage(_cipPhotoUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => setState(() => _cipPhotoUrl = null),
                            icon: const Icon(Icons.close, color: AppColors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: _isUploadingCipPhoto ? null : _pickCipPhoto,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.greyMedium,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUploadingCipPhoto)
                            const CircularProgressIndicator()
                          else ...[
                            Icon(
                              Icons.credit_card,
                              size: 48,
                              color: AppColors.greyDark,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Appuyez pour télécharger',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Description de vos services',
                  hint: 'Décrivez votre expérience et vos compétences...',
                  controller: _descriptionController,
                  maxLines: 4,
                  prefixIcon: const Icon(Icons.description_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Décrivez vos services';
                    }
                    if (value.length < 50) {
                      return 'Écrivez au moins 50 caractères';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Zone de travail simplifiée
                Text('Zone de travail', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Où travaillez-vous habituellement ?',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                ),
                const SizedBox(height: 16),

                // Ville + Quartier intelligent
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

                // Détection GPS de l'atelier
                Builder(builder: (context) {
                  final user = Provider.of<AuthProvider>(context, listen: false).userModel;
                  if (user == null) return const SizedBox.shrink();
                  return PositionClientWidget(
                    userId: user.id,
                    onPositionMiseAJour: (adresse) {
                      setState(() {
                        _currentPosition = Position.fromMap({
                          'latitude': adresse.position.latitude,
                          'longitude': adresse.position.longitude,
                          'accuracy': 0.0,
                          'altitude': 0.0,
                          'speed': 0.0,
                          'speed_accuracy': 0.0,
                          'heading': 0.0,
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                          'altitudeAccuracy': 0.0,
                          'headingAccuracy': 0.0,
                        });
                        if (adresse.ville.isNotEmpty) {
                          _selectedVille = adresse.ville;
                          _selectedQuartier = adresse.quartier.isNotEmpty
                              ? adresse.quartier
                              : _selectedQuartier;
                        }
                      });
                    },
                  );
                }),

                const SizedBox(height: 32),

                // Diplôme/Certificat
                Text('Diplôme ou Certificat', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Photo de votre diplôme, certificat ou attestation',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                ),
                const SizedBox(height: 16),

                if (_diplomeUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greyMedium),
                      image: DecorationImage(
                        image: NetworkImage(_diplomeUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => setState(() => _diplomeUrl = null),
                            icon: const Icon(Icons.close, color: AppColors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: _isUploadingDiplome ? null : _pickDiplome,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.greyMedium,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUploadingDiplome)
                            const CircularProgressIndicator()
                          else ...[
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: AppColors.greyDark,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Appuyez pour télécharger',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Photos du matériel de travail
                Text('Photos de votre matériel', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez 1 à 5 photos de vos outils ou de votre lieu de travail',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
                ),
                const SizedBox(height: 16),
                
                if (_atelierPhotosUrls.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _atelierPhotosUrls.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _atelierPhotosUrls.length) {
                        return InkWell(
                          onTap: _isUploadingPhotos ? null : _pickAtelierPhotos,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.greyMedium),
                            ),
                            child: _isUploadingPhotos
                                ? const Center(child: CircularProgressIndicator())
                                : Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 32,
                                    color: AppColors.greyDark,
                                  ),
                          ),
                        );
                      }
                      
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_atelierPhotosUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeAtelierPhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: AppColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  InkWell(
                    onTap: _isUploadingPhotos ? null : _pickAtelierPhotos,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.greyMedium,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUploadingPhotos)
                            const CircularProgressIndicator()
                          else ...[
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.greyDark,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Appuyez pour ajouter des photos',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 48),
                
                // Bouton de soumission
                CustomButton(
                  text: 'Soumettre mon profil',
                  onPressed: (_isLoading || _isUploadingDiplome || _isUploadingCipPhoto || _isUploadingPhotos)
                      ? null
                      : _submitProfile,
                  isLoading: _isLoading,
                  backgroundColor: AppColors.accentRed,
                ),
                
                const SizedBox(height: 16),
                
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 18, color: AppColors.greyDark),
                      const SizedBox(width: 6),
                      Text(
                        'Vérification sous 24-48h',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ), // Fermeture du Scaffold
    ); // Fermeture du PopScope
  }
}
