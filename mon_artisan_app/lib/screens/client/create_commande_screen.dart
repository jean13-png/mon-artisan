import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as dart_io;
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/adresse_service.dart';
import '../../models/artisan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/share_location_dialog.dart';
import '../../widgets/position_client_widget.dart';

class CreateCommandeScreen extends StatefulWidget {
  final ArtisanModel artisan;
  final String typeCommande; // 'panne_connue' ou 'diagnostic_requis'

  const CreateCommandeScreen({
    super.key,
    required this.artisan,
    this.typeCommande = 'panne_connue',
  });

  @override
  State<CreateCommandeScreen> createState() => _CreateCommandeScreenState();
}

class _CreateCommandeScreenState extends State<CreateCommandeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  AdresseDetectee? _adresseDetectee; // Position GPS détectée

  bool get _isDiagnosticMode => widget.typeCommande == 'diagnostic_requis';

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user != null) {
      // Pré-remplir avec les données du profil
      _adresseController.text =
          [user.quartier, user.ville].where((s) => s.isNotEmpty).join(', ');
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty && images.length <= 3) {
      setState(() => _selectedImages = images);
    } else if (images.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez sélectionner que 3 photos maximum'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _createCommande() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date d\'intervention'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une heure d\'intervention'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
      final user = authProvider.userModel!;

      // Créer d'abord la commande pour obtenir l'ID
      final commandeId = await commandeProvider.createCommande(
        clientId: user.id,
        artisanId: widget.artisan.userId,
        metier: widget.artisan.metier,
        typeCommande: widget.typeCommande,
        titre: _isDiagnosticMode
            ? 'Diagnostic ${widget.artisan.metier}'
            : _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        adresse: _adresseController.text.trim(),
        // Utiliser la position GPS détectée si disponible, sinon celle du profil
        position: _adresseDetectee?.position ?? user.position,
        ville: _adresseDetectee?.ville.isNotEmpty == true
            ? _adresseDetectee!.ville
            : user.ville,
        quartier: _adresseDetectee?.quartier.isNotEmpty == true
            ? _adresseDetectee!.quartier
            : user.quartier,
        dateIntervention: _selectedDate!,
        heureIntervention:
            '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        montant: 0,
        fraisDeplacement: _isDiagnosticMode ? 1000.0 : null,
        photos: [],
      );

      if (commandeId == null) {
        throw Exception('Impossible de créer la commande');
      }

      // Uploader les photos si présentes
      List<String> photoUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('[INFO] Upload de ${_selectedImages.length} photo(s)...');
        try {
          final photoPaths = _selectedImages.map((img) => img.path).toList();
          photoUrls = await commandeProvider.uploadPhotos(photoPaths, commandeId);
          print('[SUCCESS] ${photoUrls.length} photo(s) uploadée(s)');
          
          // Mettre à jour la commande avec les URLs des photos
          await FirebaseService.firestore
              .collection('commandes')
              .doc(commandeId)
              .update({
            'photos': photoUrls,
            'updatedAt': Timestamp.now(),
          });
        } catch (e) {
          print('[WARNING] Erreur upload photos: $e');
          // Continuer même si l'upload des photos échoue
        }
      }

      if (mounted) {
        // Afficher un message de succès
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Demande envoyée !', style: AppTextStyles.h3),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre demande a été envoyée à l\'artisan.',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.greyDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'L\'artisan vous enverra un devis',
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
                  Navigator.pop(context);
                  // Afficher automatiquement le modal de partage de localisation
                  ShareLocationDialog.show(
                    context: context,
                    commandeId: commandeId,
                    artisanId: widget.artisan.userId,
                  ).then((_) {
                    // Retourner à l'accueil après le partage (ou refus)
                    context.go(AppRouter.homeClient);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nouvelle commande',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Informations artisan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: widget.artisan.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              widget.artisan.photoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: AppColors.primaryBlue,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artisan.fullName.isNotEmpty
                              ? widget.artisan.fullName
                              : 'Artisan',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.artisan.metier,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Formulaire
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isDiagnosticMode ? Icons.search : Icons.build_circle,
                          color: _isDiagnosticMode ? AppColors.info : AppColors.success,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isDiagnosticMode 
                                ? 'Demande de diagnostic' 
                                : 'Détails de la commande',
                            style: AppTextStyles.h3,
                          ),
                        ),
                      ],
                    ),
                    
                    // Information sur le type
                    if (_isDiagnosticMode) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.info, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Frais de déplacement: 1000 FCFA',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),

                    // Titre (seulement pour panne connue)
                    if (!_isDiagnosticMode) ...[
                      CustomTextField(
                        label: 'Titre de la commande',
                        hint: 'Ex: Réparation robinet qui fuit',
                        controller: _titreController,
                        prefixIcon: const Icon(Icons.title),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le titre est requis';
                          }
                          if (value.length < 5) {
                            return 'Le titre doit contenir au moins 5 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    CustomTextField(
                      label: _isDiagnosticMode 
                          ? 'Décrivez le problème (même si vous ne connaissez pas la cause)'
                          : 'Description détaillée du besoin',
                      hint: _isDiagnosticMode
                          ? 'Ex: Mon robinet fait un bruit bizarre et l\'eau coule mal...'
                          : 'Décrivez en détail votre besoin...',
                      controller: _descriptionController,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La description est requise';
                        }
                        if (value.length < 20) {
                          return 'Veuillez fournir plus de détails (min 20 caractères)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Adresse
                    CustomTextField(
                      label: 'Adresse d\'intervention',
                      hint: 'Où doit intervenir l\'artisan ?',
                      controller: _adresseController,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'adresse est requise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Détection de position GPS ─────────────────────────
                    Builder(builder: (context) {
                      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
                      if (user == null) return const SizedBox.shrink();
                      return PositionClientWidget(
                        userId: user.id,
                        onPositionMiseAJour: (adresse) {
                          setState(() {
                            _adresseDetectee = adresse;
                            // Mettre à jour le champ adresse avec l'adresse lisible
                            if (adresse.adresseComplete.isNotEmpty) {
                              _adresseController.text = adresse.adresseComplete;
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),

                    // Date et heure
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.greyMedium),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.greyDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedDate != null
                                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                              : 'Sélectionner',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: _selectedDate != null
                                                ? FontWeight.w600
                                                : FontWeight.normal,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.greyMedium),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: AppColors.primaryBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Heure',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.greyDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedTime != null
                                              ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                              : 'Sélectionner',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: _selectedTime != null
                                                ? FontWeight.w600
                                                : FontWeight.normal,
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
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Information sur le processus
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isDiagnosticMode ? 'Processus de diagnostic' : 'Processus de commande',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isDiagnosticMode) ...[
                            _buildProcessStep('1', 'Vous payez 1000 FCFA de frais de déplacement'),
                            _buildProcessStep('2', 'L\'artisan se déplace pour le diagnostic'),
                            _buildProcessStep('3', 'Il vous envoie un devis détaillé'),
                            _buildProcessStep('4', 'Vous acceptez ou refusez le devis'),
                            _buildProcessStep('5', 'Si accepté: paiement et travaux'),
                          ] else ...[
                            _buildProcessStep('1', 'L\'artisan reçoit votre demande'),
                            _buildProcessStep('2', 'Il vous envoie un devis basé sur la complexité'),
                            _buildProcessStep('3', 'Vous acceptez ou refusez le devis'),
                            _buildProcessStep('4', 'Si accepté: paiement et travaux'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Photos
                    Text(
                      'Photos du problème (optionnel)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickImages,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.greyMedium,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.greyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'Ajouter des photos (max 3)'
                                  : '${_selectedImages.length} photo(s) sélectionnée(s)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.greyMedium),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      dart_io.File(_selectedImages[index].path),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image);
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100), // Espace pour le bouton fixe
          ],
        ),
      ),

      // Bouton Commander fixe en bas
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Envoyer la demande',
            onPressed: _createCommande,
            isLoading: _isLoading,
            backgroundColor: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.greyDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
