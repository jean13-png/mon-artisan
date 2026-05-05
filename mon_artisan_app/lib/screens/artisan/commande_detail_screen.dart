import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../models/commande_model.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/custom_button.dart';
import '../shared/chat_screen.dart';

class CommandeDetailScreen extends StatelessWidget {
  final CommandeModel commande;

  const CommandeDetailScreen({super.key, required this.commande});

  Future<void> _callClient(String telephone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: telephone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _accepterCommande(BuildContext context) async {
    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Accepter la commande', style: AppTextStyles.h3),
        content: Text(
          'Confirmez-vous que vous pouvez réaliser cette prestation ?',
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
            child: Text('Accepter', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await commandeProvider.accepterCommande(commande.id);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande acceptée avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _refuserCommande(BuildContext context) async {
    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Refuser la commande', style: AppTextStyles.h3),
        content: Text(
          'Êtes-vous sûr de vouloir refuser cette commande ?',
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
              backgroundColor: AppColors.error,
            ),
            child: Text('Refuser', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await commandeProvider.refuserCommande(commande.id);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande refusée'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _terminerCommande(BuildContext context) async {
    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Marquer comme terminée', style: AppTextStyles.h3),
        content: Text(
          'Confirmez-vous avoir terminé cette prestation ?',
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
            child: Text('Terminer', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await commandeProvider.terminerCommande(commande.id);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande marquée comme terminée'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.accentRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go(AppRouter.homeArtisan),
        ),
        title: Text(
          'Détails de la commande',
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
              color: _getStatutColor(commande.statut).withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatutIcon(commande.statut),
                    color: _getStatutColor(commande.statut),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatutText(commande.statut),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _getStatutColor(commande.statut),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informations client
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations client', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person_outline, 'Client', 'Client #${commande.clientId.substring(0, 8)}'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, 'Adresse', commande.adresse),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_city, 'Ville', '${commande.ville} - ${commande.quartier}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Détails de la prestation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Détails de la prestation', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.work_outline, 'Métier', commande.metier),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date',
                    '${commande.dateIntervention.day}/${commande.dateIntervention.month}/${commande.dateIntervention.year}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time, 'Heure', commande.heureIntervention),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    commande.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.greyDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Photos
            if (commande.photos.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Photos du problème', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: commande.photos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(commande.photos[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Montant
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rémunération', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Montant total',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyDark,
                        ),
                      ),
                      Text(
                        '${commande.montant.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Commission (10%)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyDark,
                        ),
                      ),
                      Text(
                        '- ${commande.commission.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vous recevrez', style: AppTextStyles.h3),
                      Text(
                        '${commande.montantArtisan.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Actions selon le statut
      bottomNavigationBar: _buildBottomActions(context),
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

  Widget? _buildBottomActions(BuildContext context) {
    if (commande.statut == 'en_attente') {
      return Container(
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
                  onPressed: () => _refuserCommande(context),
                  backgroundColor: AppColors.white,
                  textColor: AppColors.error,
                  borderColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Accepter',
                  onPressed: () => _accepterCommande(context),
                  backgroundColor: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (commande.statut == 'acceptee' || commande.statut == 'en_cours') {
      return Container(
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
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        commandeId: commande.id,
                        otherUserId: commande.clientId,
                        otherUserName: 'Client',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // TODO: Appeler le client
                  _callClient('0000000000');
                },
                icon: const Icon(Icons.phone, color: AppColors.primaryBlue),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Marquer comme terminée',
                  onPressed: () => _terminerCommande(context),
                  backgroundColor: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return null;
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return AppColors.warning;
      case 'acceptee':
        return AppColors.primaryBlue;
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

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'en_attente':
        return Icons.schedule;
      case 'acceptee':
        return Icons.check_circle;
      case 'en_cours':
        return Icons.build;
      case 'terminee':
        return Icons.done_all;
      case 'annulee':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente de votre réponse';
      case 'acceptee':
        return 'Commande acceptée';
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
}
