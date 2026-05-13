import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/artisan_model.dart';
import 'user_detail_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _clients = [];
  List<ArtisanModel> _artisans = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // Charger les clients
      final clientsSnapshot = await FirebaseService.usersCollection
          .where('roles', arrayContains: 'client')
          .get();
      
      _clients = clientsSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Charger les artisans
      final artisansSnapshot = await FirebaseService.artisansCollection.get();
      
      _artisans = artisansSnapshot.docs
          .map((doc) => ArtisanModel.fromFirestore(doc))
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('[ERROR] Erreur chargement utilisateurs: $e');
      setState(() => _isLoading = false);
    }
  }

  List<UserModel> get _filteredClients {
    if (_searchQuery.isEmpty) return _clients;
    return _clients.where((client) {
      final fullName = '${client.nom} ${client.prenom}'.toLowerCase();
      final email = client.email.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) || email.contains(query);
    }).toList();
  }

  List<ArtisanModel> get _filteredArtisans {
    if (_searchQuery.isEmpty) return _artisans;
    return _artisans.where((artisan) {
      final fullName = '${artisan.nom ?? ''} ${artisan.prenom ?? ''}'.toLowerCase();
      final email = (artisan.email ?? '').toLowerCase();
      final metier = artisan.metier.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query) || email.contains(query) || metier.contains(query);
    }).toList();
  }

  Future<void> _banUser(String userId, String userType, bool isBanned) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBanned ? 'Débannir l\'utilisateur' : 'Bannir l\'utilisateur'),
        content: Text(
          isBanned 
            ? 'Voulez-vous débannir cet utilisateur ?'
            : 'Voulez-vous bannir cet utilisateur ? Il ne pourra plus se connecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned ? AppColors.success : AppColors.error,
            ),
            child: Text(isBanned ? 'Débannir' : 'Bannir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseService.usersCollection.doc(userId).update({
        'isBanned': !isBanned,
        'bannedAt': !isBanned ? Timestamp.now() : null,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBanned ? 'Utilisateur débanni' : 'Utilisateur banni'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId, String userType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cet utilisateur ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Supprimer de users
      await FirebaseService.usersCollection.doc(userId).delete();

      // Si artisan, supprimer aussi de artisans
      if (userType == 'artisan') {
        final artisanQuery = await FirebaseService.artisansCollection
            .where('userId', isEqualTo: userId)
            .get();
        
        for (var doc in artisanQuery.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur supprimé'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _contactUser(String email, String nom) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Concernant votre compte Mon Artisan',
    );
    
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application d\'email'),
          backgroundColor: AppColors.error,
        ),
      );
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(AppRouter.adminDashboard);
            }
          },
        ),
        title: Text(
          'Gestion des Utilisateurs',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 8),
                  Text('Clients (${_filteredClients.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work),
                  const SizedBox(width: 8),
                  Text('Artisans (${_filteredArtisans.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email ou métier...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.greyLight,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Contenu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildClientsList(),
                      _buildArtisansList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    if (_filteredClients.isEmpty) {
      return const Center(
        child: Text('Aucun client trouvé'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredClients.length,
        itemBuilder: (context, index) {
          final client = _filteredClients[index];
          return _buildClientCard(client);
        },
      ),
    );
  }

  Widget _buildArtisansList() {
    if (_filteredArtisans.isEmpty) {
      return const Center(
        child: Text('Aucun artisan trouvé'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredArtisans.length,
        itemBuilder: (context, index) {
          final artisan = _filteredArtisans[index];
          return _buildArtisanCard(artisan);
        },
      ),
    );
  }

  Widget _buildClientCard(UserModel client) {
    final isBanned = client.isBanned ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: Text(
            client.prenom[0].toUpperCase(),
            style: const TextStyle(color: AppColors.white),
          ),
        ),
        title: Text('${client.prenom} ${client.nom}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.email),
            Text('${client.ville} • ${client.telephone}'),
            if (isBanned)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BANNI',
                  style: TextStyle(color: AppColors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.info, size: 20),
                  const SizedBox(width: 8),
                  const Text('Détails'),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => UserDetailScreen(
                        userId: client.id,
                        userType: 'client',
                      ),
                    ),
                  );
                });
              },
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(isBanned ? Icons.check_circle : Icons.block, size: 20),
                  const SizedBox(width: 8),
                  Text(isBanned ? 'Débannir' : 'Bannir'),
                ],
              ),
              onTap: () => _banUser(client.id, 'client', isBanned),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.email, size: 20),
                  SizedBox(width: 8),
                  Text('Contacter'),
                ],
              ),
              onTap: () => _contactUser(client.email, '${client.prenom} ${client.nom}'),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: AppColors.error)),
                ],
              ),
              onTap: () => _deleteUser(client.id, 'client'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisanCard(ArtisanModel artisan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accentRed,
          child: Text(
            (artisan.prenom?.isNotEmpty == true) ? artisan.prenom![0].toUpperCase() : 'A',
            style: const TextStyle(color: AppColors.white),
          ),
        ),
        title: Text('${artisan.prenom ?? ''} ${artisan.nom ?? ''}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(artisan.email ?? 'Email non renseigné'),
            Text('${artisan.metier} • ${artisan.ville}'),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: AppColors.warning),
                Text(' ${artisan.noteGlobale.toStringAsFixed(1)} (${artisan.nombreAvis} avis)'),
                const SizedBox(width: 8),
                Text('${artisan.nombreCommandes} commandes'),
              ],
            ),
            if (!artisan.isVerified)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NON VÉRIFIÉ',
                  style: TextStyle(color: AppColors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.info, size: 20),
                  SizedBox(width: 8),
                  Text('Détails'),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => UserDetailScreen(
                        userId: artisan.userId,
                        userType: 'artisan',
                      ),
                    ),
                  );
                });
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.email, size: 20),
                  SizedBox(width: 8),
                  Text('Contacter'),
                ],
              ),
              onTap: () => _contactUser(artisan.email ?? '', '${artisan.prenom ?? ''} ${artisan.nom ?? ''}'),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: AppColors.error)),
                ],
              ),
              onTap: () => _deleteUser(artisan.userId, 'artisan'),
            ),
          ],
        ),
      ),
    );
  }
}
