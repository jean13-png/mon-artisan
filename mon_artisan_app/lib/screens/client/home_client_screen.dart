import 'dart:async';
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
import '../../providers/commande_provider.dart';
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
  
  // Carousel
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController(viewportFraction: 0.88);
  Timer? _bannerTimer;

  final List<Map<String, String>> _banners = [
    {
      'image': 'assets/images/image1.png',
      'title': 'Des professionnels qualifiés',
      'subtitle': 'Trouvez les meilleurs artisans près de chez vous',
    },
    {
      'image': 'assets/images/image2.png',
      'title': 'Un service rapide',
      'subtitle': 'Intervention rapide et paiement sécurisé',
    },
    {
      'image': 'assets/images/image3.png',
      'title': 'Besoin d\'un dépannage ?',
      'subtitle': 'Nos artisans sont disponibles et à l\'écoute',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
      _loadUnreadCounts();
      
      // Charger les commandes du client
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        Provider.of<CommandeProvider>(context, listen: false)
            .loadClientCommandes(authProvider.userModel!.id);
      }

      // Lancer le timer pour le carousel
      _bannerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_bannerController.hasClients) {
          int nextPage = _currentBannerIndex + 1;
          if (nextPage >= _banners.length) {
            nextPage = 0;
          }
          _bannerController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
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

  void _searchByCategorie(String categorie) {
    context.push(
      '${AppRouter.categoryMetiers}?categorie=${Uri.encodeComponent(categorie)}'
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
                PopupMenuItem(
                    value: 'profile',
                    child: Row(children: [
                      Icon(Icons.person_outline, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text('Modifier mon profil',
                          style:
                              TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                    ])),
                PopupMenuItem(
                    value: 'history',
                    child: Row(children: [
                      Icon(Icons.history, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text('Mes commandes',
                          style:
                              TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                    ])),
                if (user.isArtisan)
                  PopupMenuItem(
                      value: 'switch_artisan',
                      child: Row(children: [
                        Icon(Icons.swap_horiz, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Text('Passer en mode Artisan',
                            style: TextStyle(
                                color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                      ])),
                PopupMenuItem(
                    value: 'settings',
                    child: Row(children: [
                      Icon(Icons.settings, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text('Paramètres',
                          style:
                              TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                    ])),
                PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [
                      Icon(Icons.logout, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('Déconnexion',
                          style:
                              TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
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
                              .copyWith(color: AppColors.greyDark),
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.greyDark.withValues(alpha: 0.95)),
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

              // ── Bannières / Carousel ──────────────────────────────────
              _buildBannerCarousel(),

              const SizedBox(height: 28),

              // ── Toutes les catégories ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nos catégories',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

              // ── Commandes en cours ─────────────────────────────────────
              _buildOngoingOrdersSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingOrdersSection() {
    return Consumer<CommandeProvider>(
      builder: (context, provider, child) {
        final activeCommandes = provider.commandes
            .where((c) => 
                c.statut != 'validee' && 
                c.statut != 'annulee' && 
                c.statut != 'refusee' &&
                c.statut != 'archivee')
            .toList();

        if (activeCommandes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commandes en cours',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRouter.commandesHistory),
                    child: Text('Historique',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: activeCommandes.length,
                itemBuilder: (context, index) {
                  final commande = activeCommandes[index];
                  return _buildOngoingOrderCard(commande);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOngoingOrderCard(dynamic commande) {
    return GestureDetector(
      onTap: () => context.push(AppRouter.commandeDetail, extra: commande),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(commande.statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusText(commande.statut).toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getStatusColor(commande.statut),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${commande.montant.toInt()} F',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              commande.metier,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              commande.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.greyDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.greyDark),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Prévu le ${_formatDate(commande.dateIntervention)}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'acceptee': return 'Acceptée';
      case 'diagnostic_demande': return 'Diagnostic';
      case 'diagnostic_paye': return 'Diag. payé';
      case 'diagnostic_en_cours': return 'En diagnostic';
      case 'diagnostic_valide': return 'Diag. validé';
      case 'devis_envoye': return 'Devis reçu';
      case 'devis_accepte': return 'Devis accepté';
      case 'devis_post_diagnostic_envoye': return 'Devis final';
      case 'en_cours': return 'En cours';
      case 'terminee': return 'À valider';
      case 'validee': return 'Terminée';
      case 'annulee': return 'Annulée';
      case 'refusee': return 'Refusée';
      default: return statut;
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente': return AppColors.warning;
      case 'acceptee': return AppColors.success;
      case 'diagnostic_demande': return AppColors.primaryBlue;
      case 'diagnostic_paye': return AppColors.success;
      case 'diagnostic_en_cours': return AppColors.primaryBlue;
      case 'diagnostic_valide': return AppColors.success;
      case 'devis_envoye': return AppColors.warning;
      case 'devis_accepte': return AppColors.success;
      case 'devis_post_diagnostic_envoye': return AppColors.warning;
      case 'en_cours': return AppColors.primaryBlue;
      case 'terminee': return AppColors.warning;
      case 'validee': return AppColors.success;
      case 'annulee': return AppColors.error;
      case 'refusee': return AppColors.error;
      default: return AppColors.greyDark;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Composant Bannière / Carousel ───────────────────────────────────────
  Widget _buildBannerCarousel() {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(top: 24),
      child: PageView.builder(
        controller: _bannerController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(banner['image']!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppColors.black.withOpacity(0.45),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    banner['title']!,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner['subtitle']!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                              .copyWith(color: AppColors.greyDark)),
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
                                              size: 22,
                                              color: AppColors.primaryBlue),
                                          title: Text(o,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                      color:
                                                          AppColors.onSurface)),
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
}
