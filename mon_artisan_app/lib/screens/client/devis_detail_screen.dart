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

class DevisDetailScreen extends StatefulWidget {
  final CommandeModel commande;

  const DevisDetailScreen({super.key, required this.commande});

  @override
  State<DevisDetailScreen> createState() => _DevisDetailScreenState();
}

class _DevisDetailScreenState extends State<DevisDetailScreen> {
  bool _isLoading = false;

  Future<void> _accepterDevis() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accepter le devis', style: AppTextStyles.h3),
        content: Text(
          'Confirmez-vous accepter ce devis de ${widget.commande.montantDevis!.toStringAsFixed(0)} FCFA ? Vous serez redirigé vers le paiement sécurisé.',
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
        // Rediriger vers le paiement FedaPay avec paramètres dans l'URL
        context.push(
          '${AppRouter.payment}?commandeId=${widget.commande.id}&montant=${widget.commande.montantDevis!.toStringAsFixed(0)}',
        );
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
          'Devis reçu',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.success.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Devis reçu',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.success,
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

            // Montant du devis
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
}
