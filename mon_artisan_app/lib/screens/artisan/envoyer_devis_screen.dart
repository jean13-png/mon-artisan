import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../models/commande_model.dart';
import '../../models/artisan_model.dart';
import '../../providers/commande_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EnvoyerDevisScreen extends StatefulWidget {
  final CommandeModel commande;

  const EnvoyerDevisScreen({super.key, required this.commande});

  @override
  State<EnvoyerDevisScreen> createState() => _EnvoyerDevisScreenState();
}

class _EnvoyerDevisScreenState extends State<EnvoyerDevisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCalculatingDistance = true;
  double? _distanceKm;
  ArtisanModel? _artisan;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _calculateDistance() async {
    setState(() => _isCalculatingDistance = true);
    
    try {
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      _artisan = artisanProvider.currentArtisan;
      
      if (_artisan != null) {
        final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
        
        // Calculer la distance entre l'artisan et le client
        final distance = commandeProvider.calculateDistance(
          _artisan!.position.latitude,
          _artisan!.position.longitude,
          widget.commande.position.latitude,
          widget.commande.position.longitude,
        );
        
        setState(() {
          _distanceKm = distance;
          _isCalculatingDistance = false;
        });
        
        print('[INFO] Distance calculée: ${distance.toStringAsFixed(2)} km');
      } else {
        setState(() => _isCalculatingDistance = false);
      }
    } catch (e) {
      print('[ERROR] Erreur calcul distance: $e');
      setState(() {
        _distanceKm = 0;
        _isCalculatingDistance = false;
      });
    }
  }

  Future<void> _envoyerDevis() async {
    if (!_formKey.currentState!.validate()) return;

    if (_distanceKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de calculer la distance'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
      
      final montant = double.parse(_montantController.text);
      
      final success = await commandeProvider.envoyerDevis(
        commandeId: widget.commande.id,
        montantDevis: montant,
        messageDevis: _messageController.text.trim(),
        distanceKm: _distanceKm!,
      );

      if (success && mounted) {
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
                  child: Text('Devis envoyé !', style: AppTextStyles.h3),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre devis a été envoyé au client.',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.greyDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En attente de la réponse du client',
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
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // retour à commande_detail
                  } else {
                    context.go(AppRouter.homeArtisan);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Retour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commandeProvider.errorMessage ?? 'Erreur lors de l\'envoi du devis'),
            backgroundColor: AppColors.error,
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
          'Envoyer un devis',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Informations de la commande
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Détails de la demande', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.work_outline, 'Métier', widget.commande.metier),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, 'Adresse', widget.commande.adresse),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date',
                    '${widget.commande.dateIntervention.day}/${widget.commande.dateIntervention.month}/${widget.commande.dateIntervention.year} à ${widget.commande.heureIntervention}',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.commande.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.greyDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Distance calculée
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distance', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  if (_isCalculatingDistance)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.route, color: AppColors.primaryBlue, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_distanceKm?.toStringAsFixed(2) ?? '0'} km',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Distance entre vous et le client',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.greyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Formulaire de devis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Votre devis', style: AppTextStyles.h3),
                    const SizedBox(height: 24),

                    // Montant
                    CustomTextField(
                      label: 'Montant du devis (FCFA)',
                      hint: 'Ex: 25000',
                      controller: _montantController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le montant est requis';
                        }
                        final montant = double.tryParse(value);
                        if (montant == null || montant <= 0) {
                          return 'Montant invalide';
                        }
                        if (montant < 1000) {
                          return 'Montant minimum: 1000 FCFA';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Message
                    CustomTextField(
                      label: 'Message pour le client',
                      hint: 'Expliquez votre tarif (matériel, temps, déplacement...)',
                      controller: _messageController,
                      maxLines: 5,
                      prefixIcon: const Icon(Icons.message_outlined),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le message est requis';
                        }
                        if (value.length < 20) {
                          return 'Écrivez au moins 20 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Information sur la commission
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.warning, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Commission de 10%',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_montantController.text.isNotEmpty &&
                              double.tryParse(_montantController.text) != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            _buildCalculRow(
                              'Montant total',
                              '${double.parse(_montantController.text).toStringAsFixed(0)} FCFA',
                            ),
                            const SizedBox(height: 8),
                            _buildCalculRow(
                              'Commission (10%)',
                              '- ${(double.parse(_montantController.text) * 0.10).toStringAsFixed(0)} FCFA',
                              isNegative: true,
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildCalculRow(
                              'Vous recevrez',
                              '${(double.parse(_montantController.text) * 0.90).toStringAsFixed(0)} FCFA',
                              isTotal: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bouton Envoyer
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
            text: 'Envoyer le devis',
            onPressed: _envoyerDevis,
            isLoading: _isLoading,
            backgroundColor: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.greyDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.greyDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculRow(String label, String value, {bool isNegative = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
              : AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.h3.copyWith(color: AppColors.success)
              : AppTextStyles.bodyMedium.copyWith(
                  color: isNegative ? AppColors.error : AppColors.greyDark,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
