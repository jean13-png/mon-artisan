import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
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
  String? _agentName;
  String? _agentId;
  String? _errorMessage;

  static const double FRAIS_INSCRIPTION = 958.0;
  static const double COMMISSION_AGENT = 200.0; // Commission pour l'agent

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
      // Rechercher l'agent par code de parrainage
      final agentQuery = await FirebaseService.firestore
          .collection('agents')
          .where('codeParrainage', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (agentQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Code agent invalide ou inactif';
          _agentName = null;
          _agentId = null;
          _isValidatingCode = false;
        });
        return;
      }

      final agentDoc = agentQuery.docs.first;
      final agentData = agentDoc.data();

      setState(() {
        _agentName = '${agentData['prenom']} ${agentData['nom']}';
        _agentId = agentDoc.id;
        _errorMessage = null;
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

    setState(() => _isLoading = true);

    try {
      // Simuler le paiement FedaPay (en production, utiliser la vraie API)
      // Pour le MVP, on enregistre directement le paiement
      
      // Enregistrer le paiement dans Firestore
      final paymentData = {
        'userId': authProvider.userModel!.id,
        'agentId': _agentId,
        'codeAgent': _codeController.text.trim().toUpperCase(),
        'montant': FRAIS_INSCRIPTION,
        'commissionAgent': COMMISSION_AGENT,
        'type': 'inscription_artisan',
        'statut': 'completed', // En production: 'pending' puis 'completed'
        'methode': 'mobile_money', // ou 'cash' si paiement en espèces à l'agent
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
      await _crediterAgent(_agentId!, COMMISSION_AGENT);

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement effectué avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );

      // Rediriger vers le contrat d'engagement
      context.go(AppRouter.contratEngagement);
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du paiement: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _crediterAgent(String agentId, double montant) async {
    try {
      final agentDoc = await FirebaseService.firestore
          .collection('agents')
          .doc(agentId)
          .get();

      if (agentDoc.exists) {
        final currentRevenus = (agentDoc.data()?['revenusDisponibles'] ?? 0.0).toDouble();
        final currentTotal = (agentDoc.data()?['revenusTotal'] ?? 0.0).toDouble();
        final currentInscriptions = (agentDoc.data()?['nombreInscriptions'] ?? 0);

        await FirebaseService.firestore
            .collection('agents')
            .doc(agentId)
            .update({
          'revenusDisponibles': currentRevenus + montant,
          'revenusTotal': currentTotal + montant,
          'nombreInscriptions': currentInscriptions + 1,
          'updatedAt': Timestamp.now(),
        });
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
                      '${FRAIS_INSCRIPTION.toStringAsFixed(0)} FCFA',
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
                      'Payer ${FRAIS_INSCRIPTION.toStringAsFixed(0)} FCFA',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Text(
                    'Note: Le paiement est sécurisé via Mobile Money (MTN, Moov)',
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

