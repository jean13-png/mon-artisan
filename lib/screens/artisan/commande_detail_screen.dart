import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../models/commande_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/commande_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/read_only_map_widget.dart';
import '../../core/utils/logger.dart';

class CommandeDetailScreen extends StatefulWidget {
  final CommandeModel commande;

  const CommandeDetailScreen({super.key, required this.commande});

  @override
  State<CommandeDetailScreen> createState() => _CommandeDetailScreenState();
}

class _CommandeDetailScreenState extends State<CommandeDetailScreen> {
  String? _otherUserTelephone;
  String? _otherUserNom;
  String? _otherUserPhoto;
  bool _isClient = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _loadOtherUserInfo();
  }

  void _checkRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isClient = authProvider.userModel?.id == widget.commande.clientId;
  }

  Future<void> _loadOtherUserInfo() async {
    try {
      final otherUserId = _isClient ? widget.commande.artisanId : widget.commande.clientId;
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(otherUserId)
          .get();
          
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _otherUserTelephone = data['telephone'] as String?;
          final prenom = data['prenom'] as String? ?? '';
          final nom = data['nom'] as String? ?? '';
          _otherUserNom = '$prenom $nom'.trim();
          _otherUserPhoto = data['photoUrl'] as String?;
        });
      }
    } catch (e) {
      Logger.log('[ERROR] Impossible de charger les infos de l\'autre utilisateur: $e');
    }
  }

  Future<void> _callOtherUser() async {
    final tel = _otherUserTelephone;
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseService.firestore.collection('commandes').doc(widget.commande.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Erreur: ${snapshot.error}')));
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Commande introuvable')),
            body: const Center(child: Text('Cette commande n\'existe plus.')),
          );
        }

        final commande = CommandeModel.fromFirestore(snapshot.data!);

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
                      Flexible(
                        child: Text(
                          _getStatutText(commande.statut, _isClient),
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: _getStatutColor(commande.statut),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Suivi dynamique de commande
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: _buildTrackingCard(commande),
                ),

                const SizedBox(height: 16),

                // Informations de l'autre partie
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isClient ? 'Votre artisan' : 'Informations client', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.greyLight,
                            backgroundImage: _otherUserPhoto != null ? NetworkImage(_otherUserPhoto!) : null,
                            child: _otherUserPhoto == null ? Icon(_isClient ? Icons.person : Icons.person_outline, color: AppColors.greyDark) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(
                                   _otherUserNom?.isNotEmpty == true
                                       ? _otherUserNom!
                                       : '${_isClient ? 'Artisan' : 'Client'} #${(_isClient ? commande.artisanId : commande.clientId).substring(0, 8)}',
                                   style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                 ),
                                if (_isClient)
                                  Text(commande.metier, style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _callOtherUser,
                            icon: const Icon(Icons.phone, color: AppColors.success),
                          ),
                          if (_isClient)
                            IconButton(
                              onPressed: () => _showReportDialog(context),
                              icon: const Icon(Icons.report_problem_outlined, color: AppColors.error),
                              tooltip: 'Signaler',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                          Icons.location_on_outlined, 'Adresse', commande.adresse),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_city, 'Ville',
                          '${commande.ville} - ${commande.quartier}'),
                    ],
                  ),
                ),

                // Position du client (Seul l'artisan voit la position et l'itinéraire)
                if (!_isClient && (commande.clientPosition != null)) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final position = commande.clientPosition ?? commande.position;
                      final adresse = commande.clientAdresseExacte ?? commande.adresse;
                      
                      return Container(
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
                              latitude: position.latitude,
                              longitude: position.longitude,
                              label: commande.clientPositionPartagee ? 'Position partagée (Exacte)' : 'Position d\'intervention',
                            ),
                            const SizedBox(height: 16),
                            if (adresse.isNotEmpty) ...[
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
                                        adresse,
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
                                      position.latitude,
                                      position.longitude,
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
                                if (adresse.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _copierAdresse(adresse),
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
                      );
                    }
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

                // Montant / Récapitulatif financier
                if (commande.montant > 0 || commande.montantDevis != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isClient ? 'Récapitulatif financier' : 'Rémunération', style: AppTextStyles.h3),
                        const SizedBox(height: 16),
                        
                        if (commande.montantDevis != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Montant des travaux',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: AppColors.greyDark)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  '${commande.montantDevis!.toStringAsFixed(0)} FCFA',
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        if (commande.montant > 0 && commande.typeCommande != 'diagnostic_requis') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Montant total',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: AppColors.greyDark)),
                              ),
                              const SizedBox(width: 8),
                              Text('${commande.montant.toStringAsFixed(0)} FCFA',
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ],

                        if (!_isClient && (commande.montant > 0 || commande.montantDevis != null)) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Commission (10%)',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: AppColors.greyDark)),
                              ),
                              const SizedBox(width: 8),
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
                              Expanded(
                                child: Text('Vous recevrez', style: AppTextStyles.h3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${commande.montantArtisan.toStringAsFixed(0)} FCFA',
                                style: AppTextStyles.h2
                                    .copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ] else if (_isClient && (commande.montant > 0 || commande.montantDevis != null)) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Total des travaux', style: AppTextStyles.h3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(commande.montantDevis ?? commande.montant).toStringAsFixed(0)} FCFA',
                                style: AppTextStyles.h2
                                    .copyWith(color: AppColors.primaryBlue),
                              ),
                            ],
                          ),
                          if (commande.paiementStatut == 'bloque')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.security, size: 16, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text('Paiement sécurisé en escrow', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Info en attente client (pour l'artisan)
                if (!_isClient && (commande.statut == 'devis_envoye')) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppColors.warning.withOpacity(0.1),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hourglass_empty, color: AppColors.warning),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Devis envoyé au client. En attente de son acceptation et du paiement.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Modifier le devis',
                          onPressed: () => _showModifyDevisDialog(context, commande),
                          backgroundColor: AppColors.white,
                          textColor: AppColors.primaryBlue,
                          borderColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ],

                // Description du problème (si rempli par l'artisan)
                if (commande.descriptionProbleme != null &&
                    commande.descriptionProbleme!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 24),
                            const SizedBox(width: 8),
                            Text('Rapport de diagnostic', style: AppTextStyles.h3),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(commande.descriptionProbleme!, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                        if (commande.justificationMontant != null && commande.justificationMontant!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text('Justification du montant', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(commande.justificationMontant!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark)),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomActions(context, commande),
        );
      }
    );
  }

  void _showModifyDevisDialog(BuildContext context, CommandeModel commande) {
    final TextEditingController montantController = TextEditingController(text: commande.montantDevis?.toStringAsFixed(0));
    final TextEditingController messageController = TextEditingController(text: commande.messageDevis ?? commande.descriptionProbleme);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le devis', style: AppTextStyles.h3),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nouveau montant (FCFA)',
                controller: montantController,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Message au client',
                controller: messageController,
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                bool success = await Provider.of<CommandeProvider>(context, listen: false).modifierDevis(
                    commandeId: commande.id,
                    montantDevis: double.parse(montantController.text),
                    messageDevis: messageController.text,
                  );
                
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devis modifié avec succès'), backgroundColor: AppColors.success),
                  );
                }
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Veuillez expliquer la raison de votre recours ou signalement concernant cet artisan.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reportController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Détails du problème...',
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
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reportController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir une explication')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signalement enregistré. Notre équipe va vous recontacter.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Envoyer'),
          ),
        ],
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

  Widget? _buildBottomActions(BuildContext context, CommandeModel commande) {
    if (_isClient) {
      return _buildClientActions(context, commande);
    } else {
      return _buildArtisanActions(context, commande);
    }
  }

  Widget? _buildClientActions(BuildContext context, CommandeModel commande) {
    final statut = commande.statut;

    // Action : Accepter le devis final
    if (statut == 'devis_envoye') {
      return _buildBottomBar(
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Refuser',
                onPressed: () => _refuserCommandeClient(commande),
                backgroundColor: AppColors.white,
                textColor: AppColors.error,
                borderColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            _buildChatButton(commande), // Passer la commande actuelle
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Accepter et Payer',
                onPressed: () => context.push('${AppRouter.payment}?commandeId=${commande.id}&montant=${(commande.montantDevis ?? commande.montant).toInt()}'),
                backgroundColor: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    // Action : Valider la prestation terminée
    if (statut == 'terminee') {
      return _buildBottomBar(
        child: CustomButton(
          text: 'Valider la prestation et noter',
          onPressed: () => _validerPrestationClient(commande),
          backgroundColor: AppColors.success,
        ),
      );
    }

    // Action : Marquer le service comme rendu (Validation client)
    if (statut == 'en_cours' || statut == 'acceptee') {
      return _buildBottomBar(
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Service rendu & Noter',
                onPressed: () => _validerPrestationClient(commande),
                backgroundColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            _buildChatButton(commande),
            const SizedBox(width: 8),
            _buildCallButton(),
          ],
        ),
      );
    }

    return _buildCommunicationBottomBar(commande);
  }

  Widget? _buildArtisanActions(BuildContext context, CommandeModel commande) {
    final statut = commande.statut;

    if (statut == 'en_attente') {
      return _buildBottomBar(
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
                onPressed: () => context.push(AppRouter.envoyerDevis, extra: commande),
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    if (statut == 'devis_envoye') {
       return _buildBottomBar(
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppColors.warning),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'En attente d\'acceptation du devis par le client',
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
              ),
            ),
            _buildChatButton(commande),
            const SizedBox(width: 8),
            _buildCallButton(),
          ],
        ),
      );
    }

    if (statut == 'devis_accepte' || statut == 'acceptee' || statut == 'en_cours') {
      return _buildBottomBar(
        child: Row(
          children: [
            _buildChatButton(commande),
            const SizedBox(width: 8),
            _buildCallButton(),
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
      );
    }

    return null;
  }

  Widget _buildBottomBar({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(child: child),
    );
  }

  Widget _buildCommunicationBottomBar(CommandeModel commande) {
    return _buildBottomBar(
      child: Row(
        children: [
          Expanded(child: _buildChatButton(commande)),
          const SizedBox(width: 12),
          Expanded(child: _buildCallButton()),
        ],
      ),
    );
  }

  Widget _buildChatButton(CommandeModel commande) {
    return IconButton(
      onPressed: () => context.push(AppRouter.chat, extra: {
        'otherUserId': _isClient ? commande.artisanId : commande.clientId,
        'otherUserName': _otherUserNom ?? '${_isClient ? 'Artisan' : 'Client'} #${(_isClient ? commande.artisanId : commande.clientId).substring(0, 8)}',
      }),
      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildCallButton() {
    return IconButton(
      onPressed: _callOtherUser,
      icon: const Icon(Icons.phone, color: AppColors.primaryBlue),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _refuserCommandeClient(CommandeModel commande) async {
    // Logique client pour refuser un devis
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser le devis'),
        content: const Text('Souhaitez-vous refuser ce devis ? La commande sera annulée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Oui, refuser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
       await Provider.of<CommandeProvider>(context, listen: false).refuserCommande(commande.id, 'Refusé par le client');
       Navigator.pop(context);
    }
  }

  Future<void> _validerPrestationClient(CommandeModel commande) async {
    final success = await Provider.of<CommandeProvider>(context, listen: false).validerPrestation(commande.id);
    if (success && mounted) {
      // Proposer de noter l'artisan
      _showRatingDialog(commande);
    }
  }

  void _showRatingDialog(CommandeModel commande) {
    double rating = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text('Prestation terminée !'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Comment s\'est passée l\'intervention ?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(index < rating ? Icons.star : Icons.star_border, color: AppColors.warning, size: 32),
                  onPressed: () => setModal(() => rating = index + 1.0),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(hintText: 'Votre avis...', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard')),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<CommandeProvider>(context, listen: false).noterArtisan(
                  commandeId: commande.id,
                  artisanId: commande.artisanId,
                  note: rating,
                  commentaire: commentCtrl.text.trim(),
                );
                Navigator.pop(context);
                Navigator.pop(context); // Quitter l'écran de détails
              },
              child: const Text('Envoyer'),
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

  String _getStatutText(String statut, bool isClient) {
    if (isClient) {
      switch (statut) {
        case 'en_attente': return 'En attente de l\'artisan';
        case 'devis_envoye': return 'Devis reçu - Action requise';
        case 'devis_accepte': return 'Devis accepté - Payer pour lancer';
        case 'acceptee': return 'Payé - Travaux sécurisés';
        case 'en_cours': return 'Travaux en cours...';
        case 'terminee': return 'Travaux finis - Validez la fin';
        case 'validee': return 'Prestation terminée et validée';
        case 'annulee': return 'Commande annulée';
        case 'refusee': return 'Refusée par l\'artisan';
        default: return statut;
      }
    } else {
      switch (statut) {
        case 'en_attente': return 'Nouvelle demande ! Répondez vite';
        case 'devis_envoye': return 'Devis envoyé - Attente client';
        case 'devis_accepte': return 'Accepté ! Attente paiement travaux';
        case 'acceptee': return 'Payé ! Commencez les travaux';
        case 'en_cours': return 'En cours';
        case 'terminee': return 'Fini ! Attente validation client';
        case 'validee': return 'Validée - Argent débloqué';
        case 'annulee': return 'Annulée par vous';
        case 'refusee': return 'Refusée';
        default: return statut;
      }
    }
  }

  Widget _buildTrackingCard(CommandeModel commande) {
    final steps = _trackingSteps(commande);
    final currentIndex = _currentTrackingStepIndex(commande);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suivi de la commande', style: AppTextStyles.h3),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final bool isActive = i <= currentIndex;
            final bool isLast = i == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success : AppColors.greyMedium,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive ? Icons.check : Icons.circle,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isActive ? AppColors.success : AppColors.greyMedium,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isActive ? AppColors.onSurface : AppColors.greyMedium,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        if (step.date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            step.date!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.greyDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<_TrackingStep> _trackingSteps(CommandeModel commande) {
    final steps = <_TrackingStep>[
      _TrackingStep('Demande envoyée', _fmt(commande.createdAt)),
    ];

    if (commande.acceptedAt != null) {
      steps.add(_TrackingStep('Artisan assigné', _fmt(commande.acceptedAt)));
    }
    if (commande.dateDevis != null) {
      steps.add(_TrackingStep('Devis envoyé', _fmt(commande.dateDevis)));
    }
    if (commande.dateAcceptationDevis != null) {
      steps.add(_TrackingStep('Devis accepté', _fmt(commande.dateAcceptationDevis)));
    }
    if (commande.fedapayTransactionId != null || commande.paiementStatut == 'bloque' || commande.paiementStatut == 'debloque') {
      final date = commande.dateValidationClient ?? commande.acceptedAt;
      steps.add(_TrackingStep('Paiement sécurisé', _fmt(date)));
    }
    if (commande.statut == 'en_cours' || commande.statut == 'terminee' || commande.statut == 'validee') {
      steps.add(_TrackingStep('Travaux en cours', _fmt(commande.acceptedAt)));
    }
    if (commande.statut == 'terminee' || commande.statut == 'validee') {
      steps.add(_TrackingStep('Travaux terminés', _fmt(commande.completedAt ?? commande.updatedAt)));
    }
    if (commande.statut == 'validee') {
      steps.add(_TrackingStep('Prestation validée', _fmt(commande.dateValidationClient ?? commande.dateDeblocagePaiement)));
    }

    return steps;
  }

  int _currentTrackingStepIndex(CommandeModel commande) {
    final steps = _trackingSteps(commande);
    final map = <String, int>{};
    for (var i = 0; i < steps.length; i++) {
      map[steps[i].label] = i;
    }

    final statusMap = <String, String>{
      'en_attente': 'Demande envoyée',
      'diagnostic_demande': 'Demande envoyée',
      'diagnostic_acceptee': 'Demande envoyée',
      'diagnostic_paye': 'Paiement sécurisé',
      'diagnostic_valide': 'Devis envoyé',
      'devis_envoye': 'Devis envoyé',
      'devis_accepte': 'Devis accepté',
      'devis_post_diagnostic_envoye': 'Devis envoyé',
      'devis_post_diagnostic_accepte': 'Devis accepté',
      'acceptee': 'Paiement sécurisé',
      'en_cours': 'Travaux en cours',
      'terminee': 'Travaux terminés',
      'validee': 'Prestation validée',
      'annulee': 'Demande envoyée',
      'refusee': 'Demande envoyée',
    };

    final label = statusMap[commande.statut] ?? 'Demande envoyée';
    return map[label] ?? 0;
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year} à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _TrackingStep {
  final String label;
  final String? date;

  _TrackingStep(this.label, this.date);
}
