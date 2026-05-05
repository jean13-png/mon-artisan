import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/loading_widget.dart';
import 'rate_artisan_screen.dart';

class CommandesHistoryScreen extends StatefulWidget {
  const CommandesHistoryScreen({super.key});

  @override
  State<CommandesHistoryScreen> createState() => _CommandesHistoryScreenState();
}

class _CommandesHistoryScreenState extends State<CommandesHistoryScreen> {
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        Provider.of<CommandeProvider>(context, listen: false)
            .loadClientCommandes(authProvider.userModel!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final commandeProvider = Provider.of<CommandeProvider>(context);
    
    // Filtrer les commandes selon le filtre sélectionné
    final filteredCommandes = _selectedFilter == 'Toutes'
        ? commandeProvider.commandes
        : commandeProvider.commandes.where((c) {
            switch (_selectedFilter) {
              case 'En cours':
                return c.statut == 'en_attente' || c.statut == 'acceptee' || c.statut == 'en_cours';
              case 'Terminées':
                return c.statut == 'terminee';
              case 'Annulées':
                return c.statut == 'annulee';
              default:
                return true;
            }
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            context.go(AppRouter.homeClient);
          },
        ),
        title: Text(
          'Mes commandes',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Toutes'),
                  const SizedBox(width: 8),
                  _buildFilterChip('En cours'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Terminées'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Annulées'),
                ],
              ),
            ),
          ),

          // Liste des commandes
          Expanded(
            child: commandeProvider.isLoading
                ? const LoadingWidget(message: 'Chargement...')
                : filteredCommandes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: AppColors.greyMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune commande',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.greyDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vos commandes apparaîtront ici',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.greyMedium,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          if (authProvider.userModel != null) {
                            await commandeProvider.loadClientCommandes(authProvider.userModel!.id);
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCommandes.length,
                          itemBuilder: (context, index) {
                            final commande = filteredCommandes[index];
                            return _buildCommandeCard(commande);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.greyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.greyMedium,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.greyDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCommandeCard(dynamic commande) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to commande detail for client
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commande.metier,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatutColor(commande.statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatutText(commande.statut),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getStatutColor(commande.statut),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              commande.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.greyDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.greyDark,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${commande.ville} - ${commande.quartier}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.greyDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.greyDark,
                ),
                const SizedBox(width: 4),
                Text(
                  '${commande.dateIntervention.day}/${commande.dateIntervention.month}/${commande.dateIntervention.year} à ${commande.heureIntervention}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.greyDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${commande.montant.toStringAsFixed(0)} FCFA',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (commande.statut == 'terminee' && commande.paiementStatut != 'debloque')
                  ElevatedButton(
                    onPressed: () => _validerPrestation(commande.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Valider',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (commande.statut == 'terminee' && commande.paiementStatut == 'debloque')
                  TextButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RateArtisanScreen(
                            commandeId: commande.id,
                            artisanId: commande.artisanId,
                            artisanName: 'Artisan', // TODO: Get artisan name
                          ),
                        ),
                      );
                      
                      if (result == true && context.mounted) {
                        // Recharger les commandes
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        if (authProvider.userModel != null) {
                          Provider.of<CommandeProvider>(context, listen: false)
                              .loadClientCommandes(authProvider.userModel!.id);
                        }
                      }
                    },
                    child: Text(
                      'Noter l\'artisan',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            // Afficher le statut du paiement
            if (commande.paiementStatut == 'bloque')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Paiement bloqué (escrow)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else if (commande.paiementStatut == 'debloque')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Paiement débloqué',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else if (commande.paiementStatut == 'rembourse')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.replay, size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Remboursé',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return AppColors.warning;
      case 'acceptee':
      case 'en_cours':
        return AppColors.primaryBlue;
      case 'terminee':
        return AppColors.success;
      case 'annulee':
        return AppColors.error;
      default:
        return AppColors.greyDark;
    }
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  Future<void> _validerPrestation(String commandeId) async {
    // Dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Valider la prestation',
          style: AppTextStyles.h3,
        ),
        content: Text(
          'Confirmez-vous que la prestation a été réalisée de manière satisfaisante ? Le paiement sera débloqué et crédité à l\'artisan.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.greyDark,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Valider',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Afficher un loader
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Valider la prestation
    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
    final success = await commandeProvider.validerPrestation(commandeId);

    // Fermer le loader
    if (!mounted) return;
    Navigator.pop(context);

    // Afficher le résultat
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prestation validée ! Le paiement a été débloqué.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(commandeProvider.errorMessage ?? 'Erreur lors de la validation'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
