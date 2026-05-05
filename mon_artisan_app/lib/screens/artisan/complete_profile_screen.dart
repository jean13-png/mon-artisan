import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cipController = TextEditingController();
  final _atelierAdresseController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _diplomeUrl;
  List<String> _atelierPhotosUrls = [];
  bool _isLoading = false;
  bool _isUploadingDiplome = false;
  bool _isUploadingPhotos = false;

  @override
  void dispose() {
    _cipController.dispose();
    _atelierAdresseController.dispose();
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

      if (image != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
        
        print('Uploading diplome from: ${image.path}');
        
        final url = await artisanProvider.uploadImage(
          image.path,
          'diplomes/${authProvider.userModel!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        print('Diplome uploaded successfully: $url');
        
        setState(() {
          _diplomeUrl = url;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diplôme téléchargé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error uploading diplome: $e');
      _showError('Erreur lors du téléchargement du diplôme: $e');
    } finally {
      setState(() => _isUploadingDiplome = false);
    }
  }

  Future<void> _pickAtelierPhotos() async {
    if (_atelierPhotosUrls.length >= 5) {
      _showError('Vous pouvez ajouter maximum 5 photos');
      return;
    }

    setState(() => _isUploadingPhotos = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
        
        int uploaded = 0;
        for (var image in images.take(5 - _atelierPhotosUrls.length)) {
          print('Uploading atelier photo ${uploaded + 1} from: ${image.path}');
          
          final url = await artisanProvider.uploadImage(
            image.path,
            'ateliers/${authProvider.userModel!.id}/${DateTime.now().millisecondsSinceEpoch}_$uploaded.jpg',
          );
          
          print('Photo uploaded successfully: $url');
          
          setState(() {
            _atelierPhotosUrls.add(url);
          });
          
          uploaded++;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$uploaded photo(s) téléchargée(s) avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error uploading photos: $e');
      _showError('Erreur lors du téléchargement des photos: $e');
    } finally {
      setState(() => _isUploadingPhotos = false);
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

    if (_diplomeUrl == null) {
      _showError('Veuillez télécharger votre diplôme ou certificat');
      return;
    }

    if (_atelierPhotosUrls.isEmpty) {
      _showError('Veuillez ajouter au moins une photo de votre atelier ou matériel');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      
      final success = await artisanProvider.completeArtisanProfile(
        userId: authProvider.userModel!.id,
        cip: _cipController.text.trim(),
        diplome: _diplomeUrl!,
        atelierPhotos: _atelierPhotosUrls,
        atelierAdresse: _atelierAdresseController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (success && mounted) {
        _showSuccess();
      } else if (mounted) {
        _showError(artisanProvider.errorMessage ?? 'Erreur lors de la soumission');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
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
            Text('Profil soumis !', style: AppTextStyles.h3),
          ],
        ),
        content: Text(
          'Votre profil a été soumis avec succès. Il sera vérifié par notre équipe dans les 24-48 heures. Vous recevrez une notification une fois votre profil validé.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRouter.setupLocalAuth);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Continuer'),
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
          onPressed: () => context.go(AppRouter.homeArtisan),
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
                      Icon(Icons.info_outline, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pour activer votre profil, veuillez compléter ces informations. Elles seront vérifiées par notre équipe.',
                          style: AppTextStyles.bodySmall.copyWith(
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
                
                CustomTextField(
                  label: 'Numéro CIP (Carte d\'Identité Professionnelle)',
                  hint: 'Ex: CIP123456789',
                  controller: _cipController,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le numéro CIP est requis';
                    }
                    return null;
                  },
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
                      return 'La description est requise';
                    }
                    if (value.length < 50) {
                      return 'La description doit contenir au moins 50 caractères';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Adresse de l\'atelier',
                  hint: 'Ex: Akpakpa, Rue 123',
                  controller: _atelierAdresseController,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'adresse de l\'atelier est requise';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Diplôme/Certificat
                Text('Diplôme ou Certificat', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Téléchargez une photo de votre diplôme, certificat ou attestation de formation',
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
                
                // Photos de l'atelier
                Text('Photos de l\'atelier ou matériel', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez 1 à 5 photos de votre atelier ou de vos outils de travail',
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
                  onPressed: _submitProfile,
                  isLoading: _isLoading,
                  backgroundColor: AppColors.accentRed,
                ),
                
                const SizedBox(height: 16),
                
                Center(
                  child: Text(
                    'Votre profil sera vérifié sous 24-48h',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.greyDark,
                    ),
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
