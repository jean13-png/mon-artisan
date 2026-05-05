import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../widgets/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  final String commandeId;
  final String montant;

  const PaymentScreen({
    super.key,
    required this.commandeId,
    required this.montant,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'mtn';
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // TODO: Intégrer FedaPay API
    // Pour l'instant, simulation
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isProcessing = false);
      
      // Afficher succès
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
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Paiement réussi !',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Votre commande a été envoyée à l\'artisan',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Retour à l\'accueil',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AppRouter.homeClient);
                },
                backgroundColor: AppColors.success,
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final montant = double.tryParse(widget.montant) ?? 0;
    final commission = montant * 0.10;

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go(AppRouter.homeClient),
        ),
        title: Text(
          'Paiement',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Récapitulatif
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Récapitulatif',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  _buildRecapLine('Montant de la prestation', '${montant.toStringAsFixed(0)} FCFA'),
                  const SizedBox(height: 8),
                  _buildRecapLine('Frais de service (10%)', '${commission.toStringAsFixed(0)} FCFA'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total à payer',
                        style: AppTextStyles.h3,
                      ),
                      Text(
                        '${montant.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Moyens de paiement
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choisir un moyen de paiement',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),

                  // MTN Mobile Money
                  _buildPaymentMethod(
                    'mtn',
                    'MTN Mobile Money',
                    Icons.phone_android,
                    AppColors.warning,
                  ),
                  const SizedBox(height: 12),

                  // Moov Money
                  _buildPaymentMethod(
                    'moov',
                    'Moov Money',
                    Icons.phone_android,
                    AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 12),

                  // Carte bancaire
                  _buildPaymentMethod(
                    'card',
                    'Carte bancaire',
                    Icons.credit_card,
                    AppColors.greyDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informations
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paiement sécurisé via FedaPay. Vos données sont protégées.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
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

      // Bouton Payer
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
            text: 'Payer ${montant.toStringAsFixed(0)} FCFA',
            onPressed: _processPayment,
            isLoading: _isProcessing,
            backgroundColor: AppColors.success,
          ),
        ),
      ),
    );
  }

  Widget _buildRecapLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.greyDark,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.greyMedium,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.05)
              : AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
