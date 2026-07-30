import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/artisan_provider.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../core/utils/logger.dart';
import '../../models/commande_model.dart';

class RevenusScreen extends StatefulWidget {
  const RevenusScreen({super.key});

  @override
  State<RevenusScreen> createState() => _RevenusScreenState();
}

class _RevenusScreenState extends State<RevenusScreen> {
  String _selectedPeriod = 'mois';
  final _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _stats;
  bool _isDisposed = false;
  DateTime? _lastStatsLoad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (_isDisposed) return;
    
    final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
    final artisan = artisanProvider.currentArtisan;
    
    if (artisan != null && !_isDisposed) {
      final now = DateTime.now();
      if (_lastStatsLoad == null || now.difference(_lastStatsLoad!) > const Duration(seconds: 2)) {
        _lastStatsLoad = now;
        await _loadStats(artisan.userId);
      }
      await commandeProvider.loadAllArtisanCommandes(artisan.userId);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadStats(String artisanUserId) async {
    if (_isDisposed) return;

    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case 'mois':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'trimestre':
          final currentQuarter = ((now.month - 1) ~/ 3) * 3 + 1;
          startDate = DateTime(now.year, currentQuarter, 1);
          break;
        case 'annee':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      final snapshot = await _firestore
          .collection('commandes')
          .where('artisanId', isEqualTo: artisanUserId)
          .where('statut', whereIn: ['terminee', 'validee'])
          .get();

      final commandes = snapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .where((c) {
            final date = c.completedAt ?? c.createdAt;
            return date.isAfter(startDate);
          })
          .toList();

      final totalRevenus = commandes.fold<double>(0, (total, c) => total + c.montantArtisan);

      if (!_isDisposed) {
        setState(() {
          _stats = {
            'nombreCommandes': commandes.length,
            'revenus': totalRevenus.toStringAsFixed(0),
          };
        });
      }
    } catch (e) {
      Logger.error('Erreur chargement stats', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artisanProvider = Provider.of<ArtisanProvider>(context);
    final commandeProvider = Provider.of<CommandeProvider>(context);
    final artisan = artisanProvider.currentArtisan;

    if (artisan == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Chargement...'),
      );
    }

    final commandesTerminees = commandeProvider.commandes
        .where((c) => c.statut == 'terminee' || c.statut == 'validee')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(AppRouter.homeArtisan);
            }
          },
        ),
        title: Text(
          'Mes revenus',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'En validation',
                              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<double>(
                              future: artisanProvider.getPendingValidationAmount(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text(
                                    '-- FCFA',
                                    style: AppTextStyles.h1.copyWith(
                                      color: AppColors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                final pending = snapshot.data ?? 0;
                                return Text(
                                  '${pending.toStringAsFixed(0)} FCFA',
                                  style: AppTextStyles.h1.copyWith(
                                    color: AppColors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.white.withOpacity(0.25)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Disponible',
                              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${artisan.revenusDisponibles.toStringAsFixed(0)} FCFA',
                              style: AppTextStyles.h1.copyWith(
                                color: AppColors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Total généré',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.white.withOpacity(0.6))),
                      const Spacer(),
                      Text(
                        '${artisan.revenusTotal.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bouton retrait
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: artisan.revenusDisponibles >= 5000
                          ? () => _showWithdrawalDialog(context, artisan.revenusDisponibles)
                          : null,
                      icon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.white,
                        size: 20,
                      ),
                      label: Text(
                        'Demander un retrait',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.white,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentRed,
                        elevation: 2,
                        shadowColor: AppColors.black.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (artisan.revenusDisponibles < 5000)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Minimum 5 000 FCFA requis pour un retrait',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Statistiques', style: AppTextStyles.h3),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'mois', child: Text('Ce mois')),
                          DropdownMenuItem(value: 'trimestre', child: Text('Ce trimestre')),
                          DropdownMenuItem(value: 'annee', child: Text('Cette année')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPeriod = value);
                            final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
                            final now = DateTime.now();
                            if (_lastStatsLoad == null || now.difference(_lastStatsLoad!) > const Duration(seconds: 1)) {
                              _lastStatsLoad = now;
                              _loadStats(artisanProvider.currentArtisan!.userId);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Commandes',
                          '${_stats?['nombreCommandes'] ?? 0}',
                          Icons.assignment,
                          AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Revenus',
                          '${_stats?['revenus'] ?? '0'} FCFA',
                          Icons.monetization_on,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historique des paiements', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  if (commandesTerminees.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.greyMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune transaction',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.greyDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...commandesTerminees.map((commande) {
                      return _buildTransactionCard(commande);
                    }),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.greyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic commande) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commande.metier,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(commande.completedAt ?? commande.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.greyDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ ${commande.montantArtisan.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showWithdrawalDialog(BuildContext context, double montantDisponible) {
    final montantController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Demander un retrait', style: AppTextStyles.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disponible: ${montantDisponible.toStringAsFixed(0)} FCFA',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: montantController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant à retirer',
              hintText: 'Min. 5 000 FCFA',
              suffixText: 'FCFA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: AppTextStyles.bodyMedium),
        ),
        ElevatedButton(
          onPressed: () async {
            final montant = double.tryParse(montantController.text);
            if (montant == null || montant < 5000) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Montant minimum: 5 000 FCFA'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            if (montant > montantDisponible) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Montant supérieur au solde disponible'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }

            Navigator.pop(context);

            try {
              final artisanProvider =
                  Provider.of<ArtisanProvider>(context, listen: false);
              final artisan = artisanProvider.currentArtisan!;

              final existing = await _firestore
                  .collection('retraits')
                  .where('artisanId', isEqualTo: artisan.userId)
                  .where('statut', isEqualTo: 'en_attente')
                  .limit(1)
                  .get();

              if (existing.docs.isNotEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vous avez déjà une demande de retrait en cours'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
                return;
              }

              await _firestore.runTransaction((transaction) async {
                final retraitRef = _firestore.collection('retraits').doc();
                final artisanRef = _firestore.collection('artisans').doc(artisan.id);

                transaction.set(retraitRef, {
                  'artisanId': artisan.userId,
                  'artisanDocId': artisan.id,
                  'montant': montant,
                  'statut': 'en_attente',
                  'createdAt': Timestamp.now(),
                });

                transaction.update(artisanRef, {
                  'revenusDisponibles': FieldValue.increment(-montant),
                  'updatedAt': Timestamp.now(),
                });
              });

              await artisanProvider.loadArtisanProfile(artisan.userId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Demande de retrait de ${montant.toStringAsFixed(0)} FCFA envoyée'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text('Confirmer', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}
