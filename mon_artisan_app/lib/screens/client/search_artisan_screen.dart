import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/villes_benin.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/geolocation_service.dart';
import '../../providers/artisan_provider.dart';
import '../../widgets/artisan_card.dart';
import '../../widgets/loading_widget.dart';

class SearchArtisanScreen extends StatefulWidget {
  final String? metier;
  final String? categorie;
  final String? ville;
  final String? quartier;
  final String? query;
  final int rayon;

  const SearchArtisanScreen({
    super.key,
    this.metier,
    this.categorie,
    this.ville,
    this.quartier,
    this.query,
    this.rayon = 50,
  });

  @override
  State<SearchArtisanScreen> createState() => _SearchArtisanScreenState();
}

class _SearchArtisanScreenState extends State<SearchArtisanScreen> {
  String _sortBy = 'distance'; // 'note', 'distance', 'prix'
  Position? _userPosition;
  bool _isLoadingPosition = false;

  // Filtres actifs
  late String? _activeVille;
  late String? _activeQuartier;
  late int _activeRayon;

  @override
  void initState() {
    super.initState();
    _activeVille = widget.ville;
    _activeQuartier = widget.quartier;
    _activeRayon = widget.rayon;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPosition();
    });
  }

  Future<void> _loadUserPosition() async {
    setState(() => _isLoadingPosition = true);
    try {
      final hasPermission = await GeolocationService.handleLocationPermission(context);
      if (hasPermission) {
        final position = await GeolocationService.getCurrentPosition();
        setState(() {
          _userPosition = position;
        });
      } else {
        // Fallback sur la position du profil si GPS refusé
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userModel;
        if (user != null) {
          setState(() {
            _userPosition = Position(
              latitude: user.position.latitude,
              longitude: user.position.longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          });
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() => _isLoadingPosition = false);
        await _searchArtisans();
      }
    }
  }

  Future<void> _searchArtisans() async {
    final artisanProvider =
        Provider.of<ArtisanProvider>(context, listen: false);
    await artisanProvider.searchArtisans(
      metier: widget.metier ?? widget.query,
      categorie: widget.categorie,
      ville: _activeVille,
      quartier: _activeQuartier,
      latitude: _userPosition?.latitude,
      longitude: _userPosition?.longitude,
      radiusKm: _activeRayon.toDouble(),
    );
  }

  String get _titre {
    if (widget.categorie != null) return widget.categorie!;
    if (widget.metier != null) return widget.metier!;
    if (widget.query != null && widget.query!.isNotEmpty) return widget.query!;
    return 'Tous les artisans';
  }

  @override
  Widget build(BuildContext context) {
    final artisanProvider = Provider.of<ArtisanProvider>(context);

    // Tri
    final sorted = List.from(artisanProvider.artisans);
    if (_sortBy == 'distance' && _userPosition != null) {
      sorted.sort((a, b) {
        final dA = GeolocationService.calculateDistance(_userPosition!.latitude,
            _userPosition!.longitude, a.position.latitude, a.position.longitude);
        final dB = GeolocationService.calculateDistance(_userPosition!.latitude,
            _userPosition!.longitude, b.position.latitude, b.position.longitude);
        return dA.compareTo(dB);
      });
    } else if (_sortBy == 'prix') {
      sorted.sort((a, b) {
        final pA = (a.tarifs['horaire'] ?? a.tarifs['tarifHoraire'] ?? 0) as num;
        final pB = (b.tarifs['horaire'] ?? b.tarifs['tarifHoraire'] ?? 0) as num;
        return pA.compareTo(pB);
      });
    } else {
      sorted.sort((a, b) => b.noteGlobale.compareTo(a.noteGlobale));
    }

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_titre,
            style: AppTextStyles.h3.copyWith(color: AppColors.white),
            overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.white),
            onPressed: _showFilterSheet,
            tooltip: 'Filtres',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barre de filtres actifs ──────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Chips filtres actifs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_activeVille != null)
                        _filterChip(
                          _activeVille!,
                          icon: Icons.location_on_outlined,
                          onRemove: () => setState(() {
                            _activeVille = null;
                            _activeQuartier = null;
                            _searchArtisans();
                          }),
                        ),
                      if (_activeQuartier != null)
                        _filterChip(
                          _activeQuartier!,
                          icon: Icons.home_work_outlined,
                          onRemove: () => setState(() {
                            _activeQuartier = null;
                            _searchArtisans();
                          }),
                        ),
                      _filterChip(
                        '$_activeRayon km',
                        icon: Icons.straighten,
                        isRemovable: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Tri
                Row(
                  children: [
                    Text('Trier :',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    _sortChip('Note', 'note'),
                    const SizedBox(width: 6),
                    if (_userPosition != null) ...[
                      _sortChip('Distance', 'distance'),
                      const SizedBox(width: 6),
                    ],
                    _sortChip('Prix', 'prix'),
                  ],
                ),
              ],
            ),
          ),

          // ── Résultats ────────────────────────────────────────────────
          Expanded(
            child: artisanProvider.isLoading || _isLoadingPosition
                ? const LoadingWidget(showShimmer: true)
                : RefreshIndicator(
                    onRefresh: _searchArtisans,
                    child: sorted.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final artisan = sorted[index];
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final user = authProvider.userModel;
                              
                              // On utilise la position du profil pour le calcul financier et la distance fixe
                              // pour être cohérent avec CreateCommandeScreen
                              final referencePos = user?.position ?? (_userPosition != null 
                                ? GeoPoint(_userPosition!.latitude, _userPosition!.longitude)
                                : null);

                              final distance = referencePos != null
                                  ? GeolocationService.calculateDistance(
                                      referencePos.latitude,
                                      referencePos.longitude,
                                      artisan.position.latitude,
                                      artisan.position.longitude,
                                    )
                                  : null;
                              return ArtisanCard(
                                artisan: artisan,
                                distance: distance,
                                onTap: () => context.push(
                                    AppRouter.artisanProfile,
                                    extra: artisan),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label,
      {IconData? icon, VoidCallback? onRemove, bool isRemovable = true}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
          if (isRemovable && onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  size: 14, color: AppColors.primaryBlue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.greyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primaryBlue : AppColors.greyMedium),
        ),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.white : AppColors.greyDark,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: AppColors.greyMedium),
            const SizedBox(height: 16),
            Text('Aucun artisan trouvé',
                style: AppTextStyles.h3.copyWith(color: AppColors.greyDark)),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'élargir le rayon de recherche\nou de modifier vos filtres.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.greyMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _activeVille = null;
                  _activeQuartier = null;
                  _activeRayon = 100;
                });
                _searchArtisans();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Élargir la recherche'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feuille de filtres avancés ─────────────────────────────────────────
  void _showFilterSheet() {
    String? tempVille = _activeVille;
    String? tempQuartier = _activeQuartier;
    double tempRayon = _activeRayon.toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.greyMedium,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text('Filtres', style: AppTextStyles.h3),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setModal(() {
                        tempVille = null;
                        tempQuartier = null;
                        tempRayon = 50;
                      }),
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
                          return getAllVilles()
                              .where((vi) => vi.toLowerCase().contains(q));
                        },
                        displayStringForOption: (v) => v,
                        fieldViewBuilder: (ctx, ctrl, focus, _) => TextField(
                          controller: ctrl,
                          focusNode: focus,
                          decoration: InputDecoration(
                            hintText: 'Toutes les villes',
                            prefixIcon: const Icon(Icons.location_city),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (v) => setModal(() {
                            tempVille = v.trim().isEmpty ? null : v.trim();
                            tempQuartier = null;
                          }),
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

                      // Rayon
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
                            child: Text('${tempRayon.toInt()} km',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600)),
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
                        onChanged: (v) => setModal(() => tempRayon = v),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _activeVille = tempVille;
                              _activeQuartier = tempQuartier;
                              _activeRayon = tempRayon.toInt();
                            });
                            _searchArtisans();
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Appliquer les filtres'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
