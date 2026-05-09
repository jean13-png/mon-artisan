import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/fedapay_service.dart';
import '../../providers/commande_provider.dart';
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
  String? _transactionId;

  Future<void> _processPayment() async {
    // ✅ PROTECTION 1: Empêcher double clic
    if (_isProcessing) {
      print('[WARNING] Paiement déjà en cours, ignoré');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final montant = double.tryParse(widget.montant) ?? 0;
      if (montant <= 0) {
        throw Exception('Montant invalide');
      }

      print('[INFO] Création transaction FedaPay...');
      
      // ✅ PROTECTION 2: Utiliser commandeId comme référence unique
      // FedaPay va rejeter les transactions en double avec le même custom_metadata
      final transactionData = await FedaPayService.createTransaction(
        amount: montant,
        description: 'Paiement commande ${widget.commandeId}',
        customerEmail: user.email ?? 'client@monartisan.com',
        customerPhone: user.phoneNumber ?? '+22900000000',
        commandeId: widget.commandeId, // ✅ Référence unique
      );

      // ✅ Vérifier que transactionData n'est pas null
      if (transactionData == null) {
        throw Exception('Réponse FedaPay vide (null)');
      }

      print('[SUCCESS] Transaction créée: ${transactionData['v1']?['id'] ?? 'ID manquant'}');
      
      // ✅ Vérifier que les données existent
      if (transactionData['v1'] == null) {
        throw Exception('Format de réponse FedaPay invalide');
      }
      
      if (transactionData['v1']['id'] == null) {
        throw Exception('ID transaction manquant');
      }
      
      _transactionId = transactionData['v1']['id'].toString();
      final paymentUrl = transactionData['v1']['url'] as String?;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception('URL de paiement non disponible');
      }

      // Ouvrir la page de paiement FedaPay
      final uri = Uri.parse(paymentUrl);
      
      // ✅ En mode simulation, ne pas ouvrir le navigateur
      if (AppConstants.simulateFedaPay) {
        print('[SIMULATION] Paiement simulé, pas de redirection');
        if (mounted) {
          _showPaymentVerificationDialog();
        }
      } else if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Attendre que l'utilisateur revienne et vérifier le statut
        if (mounted) {
          _showPaymentVerificationDialog();
        }
      } else {
        throw Exception('Impossible d\'ouvrir la page de paiement');
      }
    } catch (e) {
      print('[ERROR] Erreur paiement: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
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

    // Vérifier le statut après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      _verifyPaymentStatus();
    });
  }

  Future<void> _verifyPaymentStatus() async {
    if (_transactionId == null) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialog
        setState(() => _isProcessing = false);
      }
      return;
    }

    try {
      print('[INFO] Vérification statut transaction $_transactionId...');
      
      final status = await FedaPayService.checkTransactionStatus(_transactionId!);
      print('[INFO] Statut: $status');

      if (status == 'approved' || status == 'completed') {
        // ✅ PROTECTION 3: Marquer le paiement dans Firestore (avec idempotence)
        final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
        final success = await commandeProvider.effectuerPaiement(widget.commandeId);

        if (mounted) {
          Navigator.of(context).pop(); // Fermer le dialog de vérification
          
          if (success) {
            _showSuccessDialog();
          } else {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(commandeProvider.errorMessage ?? 'Erreur lors de la validation du paiement'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else if (status == 'pending') {
        // Toujours en attente, revérifier
        if (mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            _verifyPaymentStatus();
          });
        }
      } else {
        // Échec ou annulé
        if (mounted) {
          Navigator.of(context).pop(); // Fermer le dialog
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paiement ${status == 'canceled' ? 'annulé' : 'échoué'}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('[ERROR] Erreur vérification: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialog
        setState(() => _isProcessing = false);
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
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Paiement sécurisé !',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre paiement est sécurisé en escrow. L\'artisan sera payé après votre validation de la prestation.',
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

  Future<void> _cancelPayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler le paiement', style: AppTextStyles.h3),
        content: Text(
          'Êtes-vous sûr de vouloir annuler ce paiement ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Non', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Oui, annuler', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.go(AppRouter.homeClient);
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
          onPressed: _cancelPayment,
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
                  const SizedBox(height: 8),
                  Text(
                    'La commission de 10% est prélevée sur la part de l\'artisan.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.greyDark,
                      fontStyle: FontStyle.italic,
                    ),
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
