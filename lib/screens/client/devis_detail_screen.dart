import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../models/commande_model.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/fedapay_service.dart';

class DevisDetailScreen extends StatefulWidget {
  final CommandeModel commande;

  const DevisDetailScreen({super.key, required this.commande});

  @override
  State<DevisDetailScreen> createState() => _DevisDetailScreenState();
}

class _DevisDetailScreenState extends State<DevisDetailScreen> {
  bool _isLoading = false;
  String? _transactionId;

  Future<void> _accepterDevis() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accepter le devis', style: AppTextStyles.h3),
        content: Text(
          'Confirmez-vous accepter ce devis de ${widget.commande.montantDevis!.toStringAsFixed(0)} FCFA ? Vous serez redirigé vers FedaPay pour le paiement sécurisé.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text('Accepter et payer', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);

      // ✅ PROTECTION: Accepter le devis avec idempotence
      final success = await commandeProvider.accepterDevis(widget.commande.id);

      if (success && mounted) {
        // Lancement direct de FedaPay
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }

        final montant = widget.commande.montantDevis!;
        
        final transactionData = await FedaPayService.createTransaction(
          amount: montant,
          description: 'Paiement commande ${widget.commande.id}',
          customerEmail: user.email ?? 'client@monartisan.com',
          customerPhone: user.phoneNumber ?? '+22900000000',
          commandeId: widget.commande.id,
        );

        if (transactionData['v1'] == null || transactionData['v1']['id'] == null) {
          throw Exception('Format de réponse FedaPay invalide');
        }
        
        _transactionId = transactionData['v1']['id'].toString();
        final paymentUrl = transactionData['v1']['url'] as String?;

        if (paymentUrl == null || paymentUrl.isEmpty) {
          throw Exception('URL de paiement non disponible');
        }

        final uri = Uri.parse(paymentUrl);
        
        if (AppConstants.simulateFedaPay) {
          if (mounted) _showPaymentVerificationDialog();
        } else if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) _showPaymentVerificationDialog();
        } else {
          throw Exception('Impossible d\'ouvrir la page de paiement');
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commandeProvider.errorMessage ?? 'Erreur lors de l\'acceptation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPaymentVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Vérification du paiement...',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Veuillez patienter',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      _verifyPaymentStatus();
    });
  }

  Future<void> _verifyPaymentStatus() async {
    if (_transactionId == null) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final status = await FedaPayService.checkTransactionStatus(_transactionId!);

      if (!mounted) return;

      if (status == 'approved' || status == 'completed') {
        final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
        final success = await commandeProvider.effectuerPaiement(widget.commande.id);

        if (mounted) {
          Navigator.of(context).pop(); // Fermer le dialog
          setState(() => _isLoading = false);
          
          if (success) {
            _showSuccessDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(commandeProvider.errorMessage ?? 'Erreur lors de la validation'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else if (status == 'pending') {
        if (mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            _verifyPaymentStatus();
          });
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paiement ${status == 'canceled' ? 'annulé' : 'échoué'}. Commande en attente de paiement.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 50),
            ),
            const SizedBox(height: 24),
            Text('Paiement sécurisé !', style: AppTextStyles.h2.copyWith(color: AppColors.success)),
            const SizedBox(height: 12),
            Text(
              'Votre paiement est sécurisé en escrow. L\'artisan sera payé après votre validation de la prestation.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Continuer',
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le succès
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Quitter la page
                } else {
                  context.go(AppRouter.homeClient);
                }
              },
              backgroundColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _annulerCommande() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler la commande', style: AppTextStyles.h3),
        content: Text(
          'Êtes-vous sûr de vouloir annuler cette commande ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Non', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Oui, annuler', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
      final success = await commandeProvider.annulerCommande(widget.commande.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande annulée avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go(AppRouter.homeClient);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commandeProvider.errorMessage ?? 'Erreur lors de l\'annulation'),
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

  Future<void> _refuserDevis() async {
    final raisonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Refuser le devis', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pourquoi refusez-vous ce devis ?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Raison (optionnel)',
              hint: 'Ex: Prix trop élevé',
              controller: raisonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Refuser', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
      final success = await commandeProvider.refuserDevis(
        widget.commande.id,
        raisonController.text.trim().isEmpty ? null : raisonController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devis refusé'),
            backgroundColor: AppColors.success,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go(AppRouter.homeClient);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commandeProvider.errorMessage ?? 'Erreur lors du refus'),
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
          _getStatutText(widget.commande.statut),
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        actions: [
          if (['en_attente', 'diagnostic_demande', 'devis_envoye', 'devis_post_diagnostic_envoye', 'devis_accepte', 'acceptee'].contains(widget.commande.statut))
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.white),
              tooltip: 'Annuler la commande',
              onPressed: _annulerCommande,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _getStatutColor(widget.commande.statut).withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getStatutIcon(widget.commande.statut), color: _getStatutColor(widget.commande.statut), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _getStatutText(widget.commande.statut),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _getStatutColor(widget.commande.statut),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informations de la commande
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Votre demande', style: AppTextStyles.h3),
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
                  if (widget.commande.distanceKm != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.route, 'Distance', '${widget.commande.distanceKm!.toStringAsFixed(2)} km'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rapport de diagnostic (si disponible)
            if (widget.commande.descriptionProbleme != null && widget.commande.descriptionProbleme!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fact_check_outlined, color: AppColors.primaryBlue, size: 24),
                        const SizedBox(width: 8),
                        Text('Rapport de diagnostic', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.withOpacity(0.2)),
                      ),
                      child: Text(
                        widget.commande.descriptionProbleme!,
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                      ),
                    ),
                    if (widget.commande.justificationMontant != null && widget.commande.justificationMontant!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Justification du montant :', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.commande.justificationMontant!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Montant du devis
            if (widget.commande.montantDevis != null)
              Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant proposé', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${widget.commande.montantDevis!.toStringAsFixed(0)} FCFA',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Montant total à payer',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.greyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Message de l'artisan
            if (widget.commande.messageDevis != null && widget.commande.messageDevis!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Message de l\'artisan', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.commande.messageDevis!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Information
            if (['devis_envoye', 'devis_post_diagnostic_envoye'].contains(widget.commande.statut))
              Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'En acceptant ce devis, vous serez redirigé vers le paiement sécurisé.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.greyDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Boutons d'action
      bottomNavigationBar: ['devis_envoye', 'devis_post_diagnostic_envoye'].contains(widget.commande.statut) ? Container(
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
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Refuser',
                  onPressed: _refuserDevis,
                  isLoading: _isLoading,
                  backgroundColor: AppColors.white,
                  textColor: AppColors.error,
                  borderColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Accepter et payer',
                  onPressed: _accepterDevis,
                  isLoading: _isLoading,
                  backgroundColor: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ) : null,
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

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'en_attente':
      case 'diagnostic_demande':
        return AppColors.warning;
      case 'diagnostic_paye':
        return AppColors.primaryBlue;
      case 'diagnostic_valide':
        return AppColors.success;
      case 'devis_post_diagnostic_envoye':
        return AppColors.primaryBlue;
      case 'devis_post_diagnostic_accepte':
        return AppColors.success;
      case 'devis_envoye':
        return AppColors.primaryBlue;
      case 'devis_accepte':
        return AppColors.success;
      case 'devis_refuse':
        return AppColors.error;
      case 'acceptee':
      case 'en_cours':
        return AppColors.primaryBlue;
      case 'terminee':
      case 'validee':
        return AppColors.success;
      case 'annulee':
      case 'refusee':
        return AppColors.error;
      default:
        return AppColors.greyDark;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'en_attente':
      case 'diagnostic_demande':
        return Icons.schedule;
      case 'diagnostic_paye':
        return Icons.payment;
      case 'diagnostic_valide':
        return Icons.fact_check;
      case 'devis_post_diagnostic_envoye':
        return Icons.description;
      case 'devis_post_diagnostic_accepte':
        return Icons.check_circle;
      case 'devis_envoye':
        return Icons.description;
      case 'devis_accepte':
        return Icons.check_circle;
      case 'devis_refuse':
        return Icons.cancel;
      case 'acceptee':
        return Icons.check_circle;
      case 'en_cours':
        return Icons.build;
      case 'terminee':
        return Icons.done_all;
      case 'validee':
        return Icons.verified;
      case 'annulee':
      case 'refusee':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente d\'une réponse';
      case 'diagnostic_demande':
        return 'Diagnostic demandé (non payé)';
      case 'diagnostic_paye':
        return 'Diagnostic payé - En route';
      case 'diagnostic_valide':
        return 'Diagnostic effectué';
      case 'devis_post_diagnostic_envoye':
        return 'Devis reçu après diagnostic';
      case 'devis_post_diagnostic_accepte':
        return 'Devis diagnostic accepté';
      case 'devis_envoye':
        return 'Devis reçu';
      case 'devis_accepte':
        return 'Devis accepté';
      case 'devis_refuse':
        return 'Devis refusé';
      case 'acceptee':
        return 'Commande acceptée';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée (à valider)';
      case 'validee':
        return 'Validée';
      case 'annulee':
        return 'Annulée';
      case 'refusee':
        return 'Refusée';
      default:
        return statut;
    }
  }
}
