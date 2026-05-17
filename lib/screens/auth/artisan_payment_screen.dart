import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/fedapay_service.dart';
import '../../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtisanPaymentScreen extends StatefulWidget {
  final String codeAgent;

  const ArtisanPaymentScreen({
    super.key,
    required this.codeAgent,
  });

  @override
  State<ArtisanPaymentScreen> createState() => _ArtisanPaymentScreenState();
}

class _ArtisanPaymentScreenState extends State<ArtisanPaymentScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isValidatingCode = false;
  bool _isProcessingPayment = false;
  String? _agentName;
  String? _agentId;
  String? _errorMessage;
  String? _transactionId;

  static const double fraisInscription = 952.0;
  static const double commissionAgent = 300.0;

  @override
  void initState() {
    super.initState();
    _codeController.text = widget.codeAgent;
    if (widget.codeAgent.isNotEmpty) {
      _validateAgentCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateAgentCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code agent';
        _agentName = null;
        _agentId = null;
      });
      return;
    }

    setState(() {
      _isValidatingCode = true;
      _errorMessage = null;
    });

    try {
      // 1. Chercher si c'est un agent enregistré (nouvelle collection agents)
      final agentQuery = await FirebaseService.firestore
          .collection('agents')
          .where('codeParrainage', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (agentQuery.docs.isNotEmpty) {
        final data = agentQuery.docs.first.data();
        setState(() {
          _agentId = agentQuery.docs.first.id;
          _agentName = '${data['prenom']} ${data['nom']}';
          _isValidatingCode = false;
        });
        return;
      }

      // 2. Fallback: Chercher dans la collection users (si c'est un client devenu agent)
      final userQuery = await FirebaseService.firestore
          .collection('users')
          .where('codePromoAgent', isEqualTo: code)
          .where('isAgent', isEqualTo: true)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final data = userQuery.docs.first.data();
        setState(() {
          _agentId = userQuery.docs.first.id;
          _agentName = '${data['prenom']} ${data['nom']}';
          _isValidatingCode = false;
        });
        return;
      }

      setState(() {
        _errorMessage = 'Code agent invalide ou inactif';
        _isValidatingCode = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la validation du code';
        _agentName = null;
        _agentId = null;
        _isValidatingCode = false;
      });
    }
  }

  Future<void> _processPayment() async {
    // ✅ PROTECTION: Empêcher double clic
    if (_isProcessingPayment) {
      print('[WARNING] Paiement déjà en cours, ignoré');
      return;
    }

    if (_agentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez valider le code agent'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Utilisateur non connecté'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isProcessingPayment = true;
    });

    try {
      print('[INFO] Création transaction FedaPay pour inscription artisan...');
      
      // ✅ Créer la transaction FedaPay
      final transactionData = await FedaPayService.createTransaction(
        amount: fraisInscription,
        description: 'Inscription artisan - ${authProvider.userModel!.nom} ${authProvider.userModel!.prenom}',
        customerEmail: authProvider.userModel!.email,
        customerPhone: authProvider.userModel!.telephone,
        commandeId: 'inscription_${authProvider.userModel!.id}_${DateTime.now().millisecondsSinceEpoch}',
      );

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
      print('[ERROR] Erreur paiement inscription: $e');
      setState(() {
        _isLoading = false;
        _isProcessingPayment = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du paiement: $e'),
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
        setState(() {
          _isLoading = false;
          _isProcessingPayment = false;
        });
      }
      return;
    }

    try {
      print('[INFO] Vérification statut transaction $_transactionId...');
      
      final status = await FedaPayService.checkTransactionStatus(_transactionId!);
      print('[INFO] Statut: $status');

      if (status == 'approved' || status == 'completed') {
        // ✅ Paiement réussi, enregistrer dans Firestore
        await _enregistrerPaiement();
        
        if (mounted) {
          Navigator.of(context).pop(); // Fermer le dialog de vérification
          _showSuccessDialog();
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
          setState(() {
            _isLoading = false;
            _isProcessingPayment = false;
          });
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
        setState(() {
          _isLoading = false;
          _isProcessingPayment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _enregistrerPaiement() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Enregistrer le paiement dans Firestore
      final paymentData = {
        'userId': authProvider.userModel!.id,
        'agentId': _agentId,
        'codeAgent': _codeController.text.trim().toUpperCase(),
        'montant': fraisInscription,
        'commissionAgent': commissionAgent,
        'type': 'inscription_artisan',
        'statut': 'completed',
        'methode': 'fedapay',
        'transactionId': _transactionId,
        'createdAt': Timestamp.now(),
      };

      await FirebaseService.firestore
          .collection('paiements')
          .add(paymentData);

      // Mettre à jour le profil utilisateur
      await FirebaseService.firestore
          .collection('users')
          .doc(authProvider.userModel!.id)
          .update({
        'paiementInscription': true,
        'agentParrainId': _agentId,
        'codeAgentParrain': _codeController.text.trim().toUpperCase(),
        'datePaiementInscription': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Créditer la commission de l'agent
      await _crediterAgent(_agentId!, commissionAgent);

      print('[SUCCESS] Paiement inscription enregistré');
    } catch (e) {
      print('[ERROR] Erreur enregistrement paiement: $e');
      rethrow;
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
              'Paiement réussi !',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votre inscription a été validée. Vous pouvez maintenant compléter votre profil.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRouter.contratEngagement);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Continuer',
                style: AppTextStyles.button.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crediterAgent(String agentId, double montant) async {
    try {
      // 1. Essayer de créditer dans la collection 'agents'
      final agentDoc = await FirebaseService.firestore
          .collection('agents')
          .doc(agentId)
          .get();

      if (agentDoc.exists) {
        await FirebaseService.firestore
            .collection('agents')
            .doc(agentId)
            .update({
          'revenusDisponibles': FieldValue.increment(montant),
          'revenusTotal': FieldValue.increment(montant),
          'nombreInscriptions': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
        print('[SUCCESS] Agent crédité dans collection agents');
        return;
      }

      // 2. Fallback: Créditer dans la collection 'users' (pour les clients devenus agents)
      final userDoc = await FirebaseService.firestore
          .collection('users')
          .doc(agentId)
          .get();
      
      if (userDoc.exists) {
        await FirebaseService.firestore
            .collection('users')
            .doc(agentId)
            .update({
          'agentRevenusDisponibles': FieldValue.increment(montant),
          'agentRevenusTotal': FieldValue.increment(montant),
          'agentNombreInscriptions': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });
        print('[SUCCESS] Agent crédité dans collection users');
      }
    } catch (e) {
      print('Erreur lors du crédit agent: $e');
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
          onPressed: () => context.go(AppRouter.roleSelection),
        ),
        title: Text(
          'Paiement inscription',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment,
                      size: 40,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    'Frais d\'inscription artisan',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Montant
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${fraisInscription.toStringAsFixed(0)} FCFA',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Explication
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greyMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Ce paiement inclut :',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitItem('✓ Création de votre profil professionnel'),
                        _buildBenefitItem('✓ Accès illimité aux commandes'),
                        _buildBenefitItem('✓ Portefeuille électronique sécurisé'),
                        _buildBenefitItem('✓ Support client prioritaire'),
                        _buildBenefitItem('✓ Badge "Artisan Vérifié"'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Code agent
                  Text(
                    'Code de l\'agent terrain',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: 'Ex: AGENT001',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primaryBlue),
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) {
                            setState(() {
                              _agentName = null;
                              _agentId = null;
                              _errorMessage = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isValidatingCode ? null : _validateAgentCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        child: _isValidatingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'Valider',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ],
                  ),

                  // Afficher le nom de l'agent si validé
                  if (_agentName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Agent: $_agentName',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Afficher l'erreur si code invalide
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Bouton de paiement
                  ElevatedButton(
                    onPressed: _agentId != null ? _processPayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: AppColors.greyMedium,
                    ),
                    child: Text(
                      'Payer ${fraisInscription.toStringAsFixed(0)} FCFA',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Text(
                    'Note: Le paiement est sécurisé via FedaPay (Mobile Money)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.greyDark,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.greyDark,
        ),
      ),
    );
  }
}

