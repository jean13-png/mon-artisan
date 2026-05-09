import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/artisan_model.dart';
import '../../models/commande_model.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String userType; // 'client' ou 'artisan'

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserModel? _user;
  ArtisanModel? _artisan;
  List<CommandeModel> _commandes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoading = true);

    try {
      // Charger l'utilisateur
      final userDoc = await FirebaseService.usersCollection.doc(widget.userId).get();
      if (userDoc.exists) {
        _user = UserModel.fromFirestore(userDoc);
      }

      // Si artisan, charger les détails artisan
      if (widget.userType == 'artisan') {
        final artisanQuery = await FirebaseService.artisansCollection
            .where('userId', isEqualTo: widget.userId)
            .limit(1)
            .get();
        
        if (artisanQuery.docs.isNotEmpty) {
          _artisan = ArtisanModel.fromFirestore(artisanQuery.docs.first);
        }
      }

      // Charger les commandes
      Query commandesQuery;
      if (widget.userType == 'artisan') {
        commandesQuery = FirebaseService.commandesCollection
            .where('artisanId', isEqualTo: widget.userId);
      } else {
        commandesQuery = FirebaseService.commandesCollection
            .where('clientId', isEqualTo: widget.userId);
      }

      final commandesSnapshot = await commandesQuery.get();
      _commandes = commandesSnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('[ERROR] Erreur chargement détails: $e');
      setState(() => _isLoading = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Détails utilisateur',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Utilisateur introuvable'))
              : RefreshIndicator(
                  onRefresh: _loadUserDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 16),
                        if (widget.userType == 'artisan' && _artisan != null)
                          _buildArtisanInfoCard(),
                        if (widget.userType == 'artisan' && _artisan != null)
                          const SizedBox(height: 16),
                        _buildCommandesCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    final isBanned = _user!.isBanned ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: widget.userType == 'artisan' 
                      ? AppColors.accentRed 
                      : AppColors.primaryBlue,
                  child: Text(
                    _user!.prenom[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.fullName,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.userType == 'artisan' 
                              ? AppColors.accentRed.withOpacity(0.1)
                              : AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.userType == 'artisan' ? 'ARTISAN' : 'CLIENT',
                          style: TextStyle(
                            color: widget.userType == 'artisan' 
                                ? AppColors.accentRed 
                                : AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isBanned)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BANNI',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.email, 'Email', _user!.email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Téléphone', _user!.telephone),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_city, 'Ville', _user!.ville),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.home, 'Quartier', _user!.quartier),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Inscrit le',
              '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisanInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations artisan', style: AppTextStyles.h3),
            const Divider(height: 24),
            _buildInfoRow(Icons.work, 'Métier', _artisan!.metier),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.category, 'Catégorie', _artisan!.metierCategorie),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.verified,
              'Statut',
              _artisan!.isVerified ? 'Vérifié' : 'Non vérifié',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.check_circle,
              'Profil complet',
              _artisan!.isProfileComplete ? 'Oui' : 'Non',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.star,
              'Note',
              '${_artisan!.noteGlobale.toStringAsFixed(1)} (${_artisan!.nombreAvis} avis)',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.shopping_bag,
              'Commandes',
              _artisan!.nombreCommandes.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.attach_money,
              'Revenus totaux',
              '${_artisan!.revenusTotal.toStringAsFixed(0)} FCFA',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.account_balance_wallet,
              'Revenus disponibles',
              '${_artisan!.revenusDisponibles.toStringAsFixed(0)} FCFA',
            ),
            if (_artisan!.description.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Description', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_artisan!.description, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommandesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Commandes', style: AppTextStyles.h3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _commandes.length.toString(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_commandes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune commande'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _commandes.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final commande = _commandes[index];
                  return _buildCommandeItem(commande);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandeItem(CommandeModel commande) {
    Color statusColor;
    String statusText;

    switch (commande.statut) {
      case 'en_attente':
        statusColor = AppColors.warning;
        statusText = 'En attente';
        break;
      case 'devis_envoye':
        statusColor = AppColors.info;
        statusText = 'Devis envoyé';
        break;
      case 'devis_accepte':
        statusColor = AppColors.success;
        statusText = 'Devis accepté';
        break;
      case 'en_cours':
        statusColor = AppColors.primaryBlue;
        statusText = 'En cours';
        break;
      case 'terminee':
        statusColor = AppColors.success;
        statusText = 'Terminée';
        break;
      case 'annulee':
        statusColor = AppColors.error;
        statusText = 'Annulée';
        break;
      default:
        statusColor = AppColors.greyMedium;
        statusText = commande.statut;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                commande.titre,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          commande.description,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyDark),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.greyMedium),
            const SizedBox(width: 4),
            Text(
              '${commande.createdAt.day}/${commande.createdAt.month}/${commande.createdAt.year}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
            ),
            if (commande.montantDevis != null) ...[
              const SizedBox(width: 16),
              const Icon(Icons.attach_money, size: 14, color: AppColors.greyMedium),
              const SizedBox(width: 4),
              Text(
                '${commande.montantDevis!.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.greyMedium),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyDark),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
