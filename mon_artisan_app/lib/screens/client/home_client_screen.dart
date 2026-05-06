import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/metiers_data.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/metier_card.dart';
import '../../widgets/double_tap_to_exit.dart';
import '../../widgets/auth_lock_wrapper.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({super.key});

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen> {
  final _searchController = TextEditingController();
  String? _selectedVille;
  String? _selectedQuartier;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    // Pas besoin de LoadingWidget ici, juste vérifier si user existe
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.greyLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.greyDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AuthLockWrapper(
      isMainScreen: true,
      child: DoubleTapToExit(
        child: Scaffold(
        backgroundColor: AppColors.greyLight,
        appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_mon_artisan.png',
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Text(
              'Mon Artisan',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
            onPressed: () {
              context.go(AppRouter.notifications);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: AppColors.white),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go(AppRouter.editProfile);
                  break;
                case 'history':
                  context.go(AppRouter.commandesHistory);
                  break;
                case 'switch_artisan':
                  context.go(AppRouter.homeArtisan);
                  break;
                case 'logout':
                  authProvider.signOut();
                  context.go(AppRouter.roleSelection);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Modifier mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Mes commandes'),
                  ],
                ),
              ),
              if (user.isArtisan)
                const PopupMenuItem(
                  value: 'switch_artisan',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz),
                      SizedBox(width: 8),
                      Text('Passer en mode Artisan'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec salutation
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ${user.prenom} !',
                    style: AppTextStyles.h2.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quel service cherchez-vous aujourd\'hui ?',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 24),
                  
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un artisan ou un service...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.greyMedium,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.greyMedium,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () {
                            _showFilterDialog();
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _searchArtisans(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Catégories populaires
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catégories populaires',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPopularCategory('Électricien', Icons.bolt, 'electricien'),
                        _buildPopularCategory('Plombier', Icons.plumbing, 'plombier'),
                        _buildPopularCategory('Peintre', Icons.format_paint, 'peintre'),
                        _buildPopularCategory('Menuisier', Icons.carpenter, 'menuisier'),
                        _buildPopularCategory('Maçon', Icons.construction, 'macon'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Tous les métiers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tous les métiers',
                        style: AppTextStyles.h3,
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all categories
                        },
                        child: Text(
                          'Voir tout',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Grille des métiers par catégorie
                  ...metiersData.entries.take(3).map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: entry.value.take(4).length,
                          itemBuilder: (context, index) {
                            final metier = entry.value[index];
                            return MetierCard(
                              nom: metier['nom']!,
                              iconName: metier['icon']!,
                              onTap: () => _searchByMetier(metier['nom']!),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
      ), // Fermeture du Scaffold
    ), // Fermeture du DoubleTapToExit
    ); // Fermeture du AuthLockWrapper
  }

  Widget _buildPopularCategory(String name, IconData icon, String metier) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(icon, color: AppColors.primaryBlue, size: 28),
              onPressed: () => _searchByMetier(name),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _searchArtisans(String query) {
    context.go('${AppRouter.searchArtisan}?query=$query&ville=${_selectedVille ?? ''}');
  }

  void _searchByMetier(String metier) {
    context.go('${AppRouter.searchArtisan}?metier=$metier&ville=${_selectedVille ?? ''}');
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtres de recherche', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedVille,
              decoration: const InputDecoration(
                labelText: 'Ville',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Toutes les villes')),
                DropdownMenuItem(value: 'Cotonou', child: Text('Cotonou')),
                DropdownMenuItem(value: 'Porto-Novo', child: Text('Porto-Novo')),
                DropdownMenuItem(value: 'Parakou', child: Text('Parakou')),
                DropdownMenuItem(value: 'Abomey-Calavi', child: Text('Abomey-Calavi')),
              ],
              onChanged: (value) {
                setState(() => _selectedVille = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedQuartier,
              decoration: const InputDecoration(
                labelText: 'Quartier',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous les quartiers')),
                DropdownMenuItem(value: 'Akpakpa', child: Text('Akpakpa')),
                DropdownMenuItem(value: 'Ganhi', child: Text('Ganhi')),
                DropdownMenuItem(value: 'Cadjehoun', child: Text('Cadjehoun')),
                DropdownMenuItem(value: 'Fidjrosse', child: Text('Fidjrosse')),
              ],
              onChanged: (value) {
                setState(() => _selectedQuartier = value);
              },
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
              Navigator.pop(context);
              _searchArtisans(_searchController.text);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }
}
