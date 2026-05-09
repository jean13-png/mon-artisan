import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/metiers_data.dart';
import '../../core/constants/villes_benin.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/chat_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/double_tap_to_exit.dart';
import '../../widgets/location_permission_dialog.dart';
import '../../widgets/badge_icon.dart';
import '../shared/conversations_list_screen.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({super.key});

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen> {
  final _searchController = TextEditingController();
  String? _selectedVille;
  String? _selectedQuartier;
  int _unreadNotificationsCount = 0;
  int _unreadMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
      _loadUnreadCounts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.id;
    if (currentUserId == null) return;

    int notifCount = 0;
    int msgCount = 0;
    try {
      final snap = await FirebaseService.firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      notifCount = snap.docs.length;
    } catch (_) {}
    try {
      msgCount = await ChatService.getUnreadMessagesCount(currentUserId);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _unreadNotificationsCount = notifCount;
        _unreadMessagesCount = msgCount;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('has_asked_location_permission') ?? false;
    if (!asked && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        await LocationPermissionDialog.show(context);
        await prefs.setBool('has_asked_location_permission', true);
        if (mounted) setState(() {});
      }
    }
  }

  void _searchByMetier(String metier) {
    context.push(
      '${AppRouter.searchArtisan}?metier=${Uri.encodeComponent(metier)}'
      '&ville=${Uri.encodeComponent(_selectedVille ?? '')}',
    );
  }

  void _searchByCategorie(String categorie) {
    context.push(
      '${AppRouter.searchArtisan}?categorie=${Uri.encodeComponent(categorie)}'
      '&ville=${Uri.encodeComponent(_selectedVille ?? '')}',
    );
  }

  void _searchArtisans(String query) {
    context.push(
      '${AppRouter.searchArtisan}?query=${Uri.encodeComponent(query)}'
      '&ville=${Uri.encodeComponent(_selectedVille ?? '')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DoubleTapToExit(
      child: Scaffold(
        backgroundColor: AppColors.greyLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo_mon_artisan.png',
                  height: 36, fit: BoxFit.contain),
              const SizedBox(width: 8),
              Text('Mon Artisan',
                  style: AppTextStyles.h3
                      .copyWith(color: AppColors.white, fontSize: 19)),
            ],
          ),
          actions: [
            BadgeIcon(
              icon: Icons.chat_bubble_outline,
              count: _unreadMessagesCount,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ConversationsListScreen()),
                ).then((_) => _loadUnreadCounts());
              },
            ),
            BadgeIcon(
              icon: Icons.notifications_outlined,
              count: _unreadNotificationsCount,
              onPressed: () => context.push(AppRouter.notifications),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    context.push(AppRouter.editProfile);
                    break;
                  case 'history':
                    context.push(AppRouter.commandesHistory);
                    break;
                  case 'switch_artisan':
                    context.go(AppRouter.homeArtisan);
                    break;
                  case 'settings':
                    context.push(AppRouter.settings);
                    break;
                  case 'logout':
                    authProvider.signOut();
                    context.go(AppRouter.roleSelection);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'profile',
                    child: Row(children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 8),
                      Text('Modifier mon profil')
                    ])),
                const PopupMenuItem(
                    value: 'history',
                    child: Row(children: [
                      Icon(Icons.history),
                      SizedBox(width: 8),
                      Text('Mes commandes')
                    ])),
                if (user.isArtisan)
                  const PopupMenuItem(
                      value: 'switch_artisan',
                      child: Row(children: [
                        Icon(Icons.swap_horiz),
                        SizedBox(width: 8),
                        Text('Passer en mode Artisan')
                      ])),
                const PopupMenuItem(
                    value: 'settings',
                    child: Row(children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Paramètres')
                    ])),
                const PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Déconnexion')
                    ])),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + barre de recherche ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour ${user.prenom}',
                        style: AppTextStyles.h2
                            .copyWith(color: AppColors.white)),
                    const SizedBox(height: 4),
                    Text(
                      'Quel artisan cherchez-vous aujourd\'hui ?',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.white.withOpacity(0.85)),
                    ),
                    const SizedBox(height: 20),
                    // Barre de recherche
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Maçon, coiffeur, mécanicien...',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.greyMedium),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.greyMedium),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune,
                                color: AppColors.primaryBlue),
                            onPressed: _showAdvancedSearch,
                            tooltip: 'Recherche avancée',
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        onSubmitted: (v) {
                          if (v.isNotEmpty) _searchArtisans(v);
                        },
                      ),
                    ),
                    // Localisation actuelle
                    if (_selectedVille != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: _showAdvancedSearch,
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _selectedQuartier != null
                                    ? '$_selectedQuartier, $_selectedVille'
                                    : _selectedVille!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit,
                                  color: AppColors.white, size: 14),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Toutes les catégories ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nos catégories', style: AppTextStyles.h3),
                    TextButton(
                      onPressed: () => context.push(AppRouter.searchArtisan),
                      child: Text('Voir tout',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Grille des catégories avec images réelles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: metiersData.keys.length,
                  itemBuilder: (context, index) {
                    final categorie = metiersData.keys.elementAt(index);
                    return _buildCategorieCard(categorie);
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carte catégorie avec image réelle ──────────────────────────────────
  Widget _buildCategorieCard(String categorie) {
    final nbMetiers = metiersData[categorie]?.length ?? 0;
    return GestureDetector(
      onTap: () => _searchByCategorie(categorie),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            CachedNetworkImage(
              imageUrl: categoryImageUrl(categorie),
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.primaryBlue.withOpacity(0.15),
                child: Icon(categoryIcon(categorie),
                    color: AppColors.primaryBlue, size: 36),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.primaryBlue.withOpacity(0.15),
                child: Icon(categoryIcon(categorie),
                    color: AppColors.primaryBlue, size: 36),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                color: AppColors.primaryBlue.withValues(alpha: 0.94),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categorie,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$nbMetiers métiers',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recherche avancée (style Facebook Marketplace) ─────────────────────
  void _showAdvancedSearch() {
    String? tempVille = _selectedVille;
    String? tempQuartier = _selectedQuartier;
    String? tempCategorie;
    double tempRayon = 10.0;
    final searchCtrl = TextEditingController(text: _searchController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text('Recherche avancée', style: AppTextStyles.h3),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModal(() {
                          tempVille = null;
                          tempQuartier = null;
                          tempCategorie = null;
                          tempRayon = 10.0;
                          searchCtrl.clear();
                        });
                      },
                      child: Text('Réinitialiser',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.accentRed)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recherche texte
                      Text('Que cherchez-vous ?',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Maçon, coiffeur, mécanicien...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Catégorie avec autocomplétion
                      Text('Catégorie',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(
                            text: tempCategorie ?? ''),
                        optionsBuilder: (v) => searchCategories(v.text),
                        displayStringForOption: (c) => c,
                        fieldViewBuilder:
                            (ctx, ctrl, focus, onSubmit) => TextField(
                          controller: ctrl,
                          focusNode: focus,
                          decoration: InputDecoration(
                            hintText: 'Tapez une catégorie...',
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        onSelected: (c) =>
                            setModal(() => tempCategorie = c),
                        optionsViewBuilder: (ctx, onSel, opts) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 200),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: opts
                                    .map((o) => ListTile(
                                          leading: Icon(categoryIcon(o),
                                              size: 20),
                                          title: Text(o,
                                              style:
                                                  AppTextStyles.bodyMedium),
                                          onTap: () => onSel(o),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Ville
                      Text('Ville',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        initialValue:
                            TextEditingValue(text: tempVille ?? ''),
                        optionsBuilder: (v) {
                          if (v.text.isEmpty) return getAllVilles();
                          final q = v.text.toLowerCase();
                          return getAllVilles().where(
                              (vi) => vi.toLowerCase().contains(q));
                        },
                        displayStringForOption: (v) => v,
                        fieldViewBuilder:
                            (ctx, ctrl, focus, onSubmit) => TextField(
                          controller: ctrl,
                          focusNode: focus,
                          decoration: InputDecoration(
                            hintText: 'Tapez votre ville...',
                            prefixIcon:
                                const Icon(Icons.location_city),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (v) {
                            setModal(() {
                              tempVille = v.trim();
                              tempQuartier = null;
                            });
                          },
                        ),
                        onSelected: (v) => setModal(() {
                          tempVille = v;
                          tempQuartier = null;
                        }),
                      ),

                      const SizedBox(height: 16),

                      // Quartier
                      Text('Quartier',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (tempVille == null || tempVille!.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.greyLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.greyMedium),
                          ),
                          child: Text('Sélectionnez d\'abord une ville',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.greyMedium)),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: tempQuartier,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Tous les quartiers',
                            prefixIcon:
                                const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null,
                                child: Text('Tous les quartiers')),
                            ...getQuartiers(tempVille!).map((q) =>
                                DropdownMenuItem(
                                    value: q, child: Text(q))),
                          ],
                          onChanged: (q) =>
                              setModal(() => tempQuartier = q),
                        ),

                      const SizedBox(height: 20),

                      // Rayon de distance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rayon de recherche',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${tempRayon.toInt()} km',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: tempRayon,
                        min: 1,
                        max: 100,
                        divisions: 19,
                        activeColor: AppColors.primaryBlue,
                        label: '${tempRayon.toInt()} km',
                        onChanged: (v) =>
                            setModal(() => tempRayon = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 km',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.greyDark)),
                          Text('100 km',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.greyDark)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Bouton Rechercher
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedVille = tempVille;
                              _selectedQuartier = tempQuartier;
                            });
                            // Construire l'URL de recherche
                            final params = <String, String>{};
                            if (searchCtrl.text.isNotEmpty) {
                              params['query'] = searchCtrl.text.trim();
                            }
                            if (tempCategorie != null) {
                              params['categorie'] = tempCategorie!;
                            }
                            if (tempVille != null && tempVille!.isNotEmpty) {
                              params['ville'] = tempVille!;
                            }
                            if (tempQuartier != null) {
                              params['quartier'] = tempQuartier!;
                            }
                            params['rayon'] = tempRayon.toInt().toString();

                            final query = params.entries
                                .map((e) =>
                                    '${e.key}=${Uri.encodeComponent(e.value)}')
                                .join('&');
                            context.push(
                                '${AppRouter.searchArtisan}?$query');
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Rechercher des artisans'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Méthodes utilitaires ──────────────────────────────────────────────
  
  /// Retourne l'URL de l'image pour une catégorie donnée
  String categoryImageUrl(String categorie) {
    final imageMap = {
      'Bâtiment et Construction': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400',
      'Électricité et Plomberie': 'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=400',
      'Mécanique et Automobile': 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400',
      'Beauté et Bien-être': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
      'Couture et Mode': 'https://images.unsplash.com/photo-1558769132-cb1aea3c8565?w=400',
      'Alimentation et Restauration': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400',
      'Nettoyage et Entretien': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
      'Technologie et Réparation': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=400',
      'Art et Décoration': 'https://images.unsplash.com/photo-1513519245088-0e12902e35ca?w=400',
      'Agriculture et Jardinage': 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=400',
      'Transport et Logistique': 'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=400',
      'Éducation et Formation': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400',
      'Santé et Soins': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400',
      'Événementiel et Animation': 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=400',
      'Sécurité et Surveillance': 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=400',
    };
    return imageMap[categorie] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400';
  }

  /// Retourne l'icône appropriée pour une catégorie
  IconData categoryIcon(String categorie) {
    final iconMap = {
      'Bâtiment et Construction': Icons.construction,
      'Électricité et Plomberie': Icons.electrical_services,
      'Mécanique et Automobile': Icons.build,
      'Beauté et Bien-être': Icons.spa,
      'Couture et Mode': Icons.checkroom,
      'Alimentation et Restauration': Icons.restaurant,
      'Nettoyage et Entretien': Icons.cleaning_services,
      'Technologie et Réparation': Icons.computer,
      'Art et Décoration': Icons.palette,
      'Agriculture et Jardinage': Icons.yard,
      'Transport et Logistique': Icons.local_shipping,
      'Éducation et Formation': Icons.school,
      'Santé et Soins': Icons.medical_services,
      'Événementiel et Animation': Icons.celebration,
      'Sécurité et Surveillance': Icons.security,
    };
    return iconMap[categorie] ?? Icons.work;
  }

  /// Recherche de catégories avec autocomplétion
  Iterable<String> searchCategories(String query) {
    if (query.isEmpty) return metiersData.keys;
    final q = query.toLowerCase();
    return metiersData.keys.where((cat) => cat.toLowerCase().contains(q));
  }
}
