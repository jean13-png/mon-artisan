import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../models/commande_model.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/custom_button.dart';
import '../shared/chat_screen.dart';
import '../../widgets/read_only_map_widget.dart';
import 'envoyer_devis_screen.dart';

class CommandeDetailScreen extends StatefulWidget {
  final CommandeModel commande;

  const CommandeDetailScreen({super.key, required this.commande});

  @override
  State<CommandeDetailScreen> createState() => _CommandeDetailScreenState();
}

class _CommandeDetailScreenState extends State<CommandeDetailScreen> {
  String? _clientTelephone;
  String? _clientNom;

  @override
  void initState() {
    super.initState();
    _loadClientInfo();
  }

  Future<void> _loadClientInfo() async {
    try {
      final doc = await FirebaseService.usersCollection
          .doc(widget.commande.clientId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _clientTelephone = data['telephone'] as String?;
          final prenom = data['prenom'] as String? ?? '';
          final nom = data['nom'] as String? ?? '';
          _clientNom = '$prenom $nom'.trim();
        });
      }
    } catch (e) {
      print('[ERROR] Impossible de charger les infos client: $e');
    }
  }

  Future<void> _callClient() async {
    final tel = _clientTelephone;
    if (tel == null || tel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone non disponible'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: tel);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _ouvrirGoogleMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      final fallbackUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      await launchUrl(Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  void _copierAdresse(String adresse) {
    Clipboard.setData(ClipboardData(text: adresse));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.white),
            SizedBox(width: 12),
            Text('Adresse copiée'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refuserCommande() async {
    final commandeProvider =
        Provider.of<CommandeProvider>(context, listen: false);

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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Refuser', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await commandeProvider.refuserCommande(widget.commande.id);
      if (success && mounted) {
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

  Future<void> _terminerCommande() async {
    final commandeProvider =
        Provider.of<CommandeProvider>(context, listen: false);

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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text('Terminer', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await commandeProvider.terminerCommande(widget.commande.id);
      if (success && mounted) {
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
    final commande = widget.commande;

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.accentRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
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
                  _buildInfoRow(
                    Icons.person_outline,
                    'Client',
                    _clientNom?.isNotEmpty == true
                        ? _clientNom!
                        : 'Client #${commande.clientId.substring(0, 8)}',
                  ),
                  const SizedBox(height: 12),
                  if (_clientTelephone != null && _clientTelephone!.isNotEmpty)
                    _buildInfoRow(
                        Icons.phone, 'Téléphone', _clientTelephone!),
                  if (_clientTelephone != null && _clientTelephone!.isNotEmpty)
                    const SizedBox(height: 12),
                  _buildInfoRow(
                      Icons.location_on_outlined, 'Adresse', commande.adresse),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_city, 'Ville',
                      '${commande.ville} - ${commande.quartier}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Position du client (si partagée)
            if (commande.clientPositionPartagee &&
                commande.clientPosition != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.primaryBlue, size: 24),
                        const SizedBox(width: 8),
                        Text('Position du client', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ReadOnlyMapWidget(
                      latitude: commande.clientPosition!.latitude,
                      longitude: commande.clientPosition!.longitude,
                      label: 'Position partagée',
                    ),
                    const SizedBox(height: 16),
                    if (commande.clientAdresseExacte != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place,
                                color: AppColors.greyDark, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                commande.clientAdresseExacte!,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _ouvrirGoogleMaps(
                              commande.clientPosition!.latitude,
                              commande.clientPosition!.longitude,
                            ),
                            icon: const Icon(Icons.directions, size: 20),
                            label: const Text('Itinéraire'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: AppColors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        if (commande.clientAdresseExacte != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _copierAdresse(commande.clientAdresseExacte!),
                              icon: const Icon(Icons.copy, size: 20),
                              label: const Text('Copier'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                    color: AppColors.primaryBlue),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                  _buildInfoRow(
                      Icons.access_time, 'Heure', commande.heureIntervention),
                  if (commande.distanceKm != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.route, 'Distance',
                        '${commande.distanceKm!.toStringAsFixed(2)} km'),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    commande.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.greyDark, height: 1.5),
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
            if (commande.montant > 0 || commande.montantDevis != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rémunération', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    if (commande.montantDevis != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Montant du devis',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.greyDark)),
                          Text(
                              '${commande.montantDevis!.toStringAsFixed(0)} FCFA',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (commande.montant > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Montant total',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.greyDark)),
                          Text('${commande.montant.toStringAsFixed(0)} FCFA',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Commission (10%)',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.greyDark)),
                          Text(
                              '- ${commande.commission.toStringAsFixed(0)} FCFA',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.error)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vous recevrez', style: AppTextStyles.h3),
                          Text(
                            '${commande.montantArtisan.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.h2
                                .copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
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
              Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.greyDark)),
              const SizedBox(height: 4),
              Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions(BuildContext context) {
    final statut = widget.commande.statut;

    if (statut == 'en_attente' || statut == 'diagnostic_demande') {
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
                  onPressed: _refuserCommande,
                  backgroundColor: AppColors.white,
                  textColor: AppColors.error,
                  borderColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Envoyer un devis',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EnvoyerDevisScreen(commande: widget.commande),
                      ),
                    );
                  },
                  backgroundColor: AppColors.accentRed,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (statut == 'devis_accepte' ||
        statut == 'acceptee' ||
        statut == 'en_cours') {
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
                        otherUserId: widget.commande.clientId,
                        otherUserName: _clientNom ?? 'Client',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline,
                    color: AppColors.primaryBlue),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _callClient,
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
                  onPressed: _terminerCommande,
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
      case 'diagnostic_demande':
        return AppColors.warning;
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
        return AppColors.error;
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
        return Icons.cancel;
      case 'refusee':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente de votre réponse';
      case 'diagnostic_demande':
        return 'Diagnostic demandé';
      case 'devis_envoye':
        return 'Devis envoyé - En attente du client';
      case 'devis_accepte':
        return 'Devis accepté - En attente du paiement';
      case 'devis_refuse':
        return 'Devis refusé par le client';
      case 'acceptee':
        return 'Commande acceptée - Paiement sécurisé';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée - En attente de validation';
      case 'validee':
        return 'Validée - Paiement débloqué';
      case 'annulee':
        return 'Annulée';
      case 'refusee':
        return 'Refusée par l\'artisan';
      default:
        return statut;
    }
  }
}
