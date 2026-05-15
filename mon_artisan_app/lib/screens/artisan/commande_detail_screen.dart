import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      print('[ERROR] Impossible de charger les infos de l\'autre utilisateur: $e');
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

  Future<void> _validerDiagnostic() async {
    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmer le diagnostic', style: AppTextStyles.h3),
        content: Text(
          'Confirmez-vous être arrivé chez le client et avoir commencé le diagnostic ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: AppTextStyles.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: Text('Confirmer', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await commandeProvider.validerDiagnosticArtisan(widget.commande.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnostic validé. Vous pouvez maintenant envoyer votre devis.'),
            backgroundColor: AppColors.success,
          ),
        );
        // On ne ferme pas la page car l'artisan doit maintenant remplir le devis
        setState(() {}); 
      }
    }
  }

  Widget _buildDevisPostDiagnosticSection(BuildContext context, CommandeModel commande) {
    final TextEditingController montantController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController justificationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      color: AppColors.white,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soumettre votre devis final', style: AppTextStyles.h3.copyWith(color: AppColors.primaryBlue)),
            const SizedBox(height: 8),
            Text(
              'Après avoir analysé la panne, indiquez le montant total des travaux (hors frais de diagnostic déjà payés).',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Montant total des travaux (FCFA)',
              hint: 'Ex: 15000',
              controller: montantController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.monetization_on_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Montant requis';
                if (double.tryParse(value) == null) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Rapport détaillé / Pièces à changer',
              hint: 'Détaillez ce que vous avez trouvé et ce qu\'il faut faire...',
              controller: descriptionController,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Rapport requis';
                if (value.length < 20) return 'Soyez plus précis (min 20 car.)';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Justification du prix (optionnel)',
              hint: 'Détaillez le coût des pièces ou de la main d\'œuvre...',
              controller: justificationController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Envoyer le devis final',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final success = await Provider.of<CommandeProvider>(context, listen: false)
                        .soumettreDevisPostDiagnostic(
                      commandeId: commande.id,
                      montantDevis: double.parse(montantController.text),
                      descriptionProbleme: descriptionController.text.trim(),
                      justificationMontant: justificationController.text.trim(),
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Devis envoyé au client'), backgroundColor: AppColors.success),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
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
            // Badge DIAGNOSTIC
            if (commande.typeCommande == 'diagnostic_requis')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.primaryBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search, color: AppColors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'DIAGNOSTIC',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (commande.montantDiagnostic != null) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Frais : ${commande.montantDiagnostic!.toStringAsFixed(0)} FCFA',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

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
                    _getStatutText(commande.statut, _isClient),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _getStatutColor(commande.statut),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
                                  : (_isClient ? 'Artisan' : 'Client') + ' #${(_isClient ? widget.commande.artisanId : widget.commande.clientId).substring(0, 8)}',
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_isClient)
                              Text(widget.commande.metier, style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _callOtherUser,
                        icon: const Icon(Icons.phone, color: AppColors.success),
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

            // Montant / Récapitulatif financier
            if (commande.montant > 0 || commande.montantDevis != null || (commande.typeCommande == 'diagnostic_requis' && commande.montantDiagnostic != null)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isClient ? 'Récapitulatif financier' : 'Rémunération', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    
                    // Frais de diagnostic (si applicable)
                    if (commande.typeCommande == 'diagnostic_requis' && commande.montantDiagnostic != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Frais de diagnostic (déplacement)',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.greyDark)),
                          Text(
                              '${commande.montantDiagnostic!.toStringAsFixed(0)} FCFA',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: commande.fraisDeplacementPayes == true ? FontWeight.bold : FontWeight.normal,
                                color: commande.fraisDeplacementPayes == true ? AppColors.success : AppColors.onSurface,
                              )),
                        ],
                      ),
                      if (commande.fraisDeplacementPayes == true)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('Payé', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 12),
                    ],

                    if (commande.montantDevis != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Montant des travaux',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.greyDark)),
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
                          Text('Montant total',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.greyDark)),
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
                    ] else if (_isClient && (commande.montant > 0 || commande.montantDevis != null)) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total des travaux', style: AppTextStyles.h3),
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

            // Section devis post-diagnostic (si diagnostic validé)
            if (commande.typeCommande == 'diagnostic_requis' &&
                commande.statut == 'diagnostic_valide') ...[
              const SizedBox(height: 16),
              _buildDevisPostDiagnosticSection(context, commande),
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
    final commande = widget.commande;
    final statut = commande.statut;

    if (_isClient) {
      return _buildClientActions(context, commande);
    } else {
      return _buildArtisanActions(context, commande);
    }
  }

  Widget? _buildClientActions(BuildContext context, CommandeModel commande) {
    final statut = commande.statut;

    // Action : Payer les frais de déplacement
    if (statut == 'diagnostic_demande' && commande.fraisDeplacementPayes != true) {
      return _buildBottomBar(
        child: CustomButton(
          text: 'Payer les frais de déplacement (${commande.montantDiagnostic?.toInt()} F)',
          onPressed: () => context.push(AppRouter.payment, extra: commande),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }

    // Action : Accepter le devis final
    if (statut == 'devis_envoye' || statut == 'devis_post_diagnostic_envoye') {
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
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Accepter et Payer',
                onPressed: () => context.push(AppRouter.payment, extra: commande),
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

    // Actions par défaut (Chat / Appel)
    return _buildCommunicationBottomBar();
  }

  Widget? _buildArtisanActions(BuildContext context, CommandeModel commande) {
    final statut = commande.statut;

    // Diagnostic payé mais pas encore validé par l'artisan
    if (statut == 'diagnostic_paye' && !commande.diagnosticValideArtisan) {
      return _buildBottomBar(
        child: ElevatedButton.icon(
          onPressed: _validerDiagnostic,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Valider le diagnostic (je suis sur place)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (statut == 'en_attente' || statut == 'diagnostic_demande') {
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnvoyerDevisScreen(commande: widget.commande),
                    ),
                  );
                },
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    if (statut == 'devis_accepte' || statut == 'acceptee' || statut == 'en_cours') {
      return _buildBottomBar(
        child: Row(
          children: [
            _buildChatButton(),
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

  Widget _buildCommunicationBottomBar() {
    return _buildBottomBar(
      child: Row(
        children: [
          Expanded(child: _buildChatButton()),
          const SizedBox(width: 12),
          Expanded(child: _buildCallButton()),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: _isClient ? widget.commande.artisanId : widget.commande.clientId,
              otherUserName: _otherUserNom ?? (_isClient ? 'Artisan' : 'Client'),
            ),
          ),
        );
      },
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
      case 'diagnostic_demande':
        return AppColors.warning;
      case 'diagnostic_paye':
        return AppColors.primaryBlue;
      case 'diagnostic_valide':
        return AppColors.success;
      case 'devis_post_diagnostic_envoye':
        return AppColors.primaryBlue;
      case 'devis_post_diagnostic_accepte':
        return AppColors.success;
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
      case 'diagnostic_paye':
        return Icons.payment;
      case 'diagnostic_valide':
        return Icons.fact_check;
      case 'devis_post_diagnostic_envoye':
        return Icons.description;
      case 'devis_post_diagnostic_accepte':
        return Icons.check_circle;
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
        case 'diagnostic_demande': return 'Payer les frais de déplacement';
        case 'diagnostic_paye': return 'Frais payés - Artisan en route';
        case 'diagnostic_en_cours': return 'Diagnostic en cours...';
        case 'diagnostic_valide': return 'Diagnostic fini - Devis en attente';
        case 'devis_envoye': return 'Devis reçu - Action requise';
        case 'devis_post_diagnostic_envoye': return 'Devis final reçu - Action requise';
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
        case 'diagnostic_demande': return 'En attente du paiement client';
        case 'diagnostic_paye': return 'Payé ! Allez faire le diagnostic';
        case 'diagnostic_en_cours': return 'Diagnostic en cours';
        case 'diagnostic_valide': return 'Diagnostic validé - Envoyez le devis';
        case 'devis_envoye': return 'Devis envoyé - Attente client';
        case 'devis_post_diagnostic_envoye': return 'Devis final envoyé';
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
}
