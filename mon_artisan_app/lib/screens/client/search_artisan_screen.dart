import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/geolocation_service.dart';
import '../../providers/artisan_provider.dart';
import '../../widgets/artisan_card.dart';
import '../../widgets/loading_widget.dart';

class SearchArtisanScreen extends StatefulWidget {
  final String? metier;
  final String? ville;
  final String? query;

  const SearchArtisanScreen({
    super.key,
    this.metier,
    this.ville,
    this.query,
  });

  @override
  State<SearchArtisanScreen> createState() => _SearchArtisanScreenState();
}

class _SearchArtisanScreenState extends State<SearchArtisanScreen> {
  String _sortBy = 'note'; // 'note', 'distance', 'prix'
  Position? _userPosition;
  bool _isLoadingPosition = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPosition();
      _searchArtisans();
    });
  }

  Future<void> _loadUserPosition() async {
    setState(() => _isLoadingPosition = true);
    try {
      final position = await GeolocationService.getCurrentPosition();
      setState(() {
        _userPosition = position;
        _isLoadingPosition = false;
      });
    } catch (e) {
      setState(() => _isLoadingPosition = false);
      // Position non disponible, continuer sans
    }
  }

  Future<void> _searchArtisans() async {
    final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
    await artisanProvider.searchArtisans(
      metier: widget.metier,
      ville: widget.ville,
      latitude: _userPosition?.latitude,
      longitude: _userPosition?.longitude,
      radiusKm: 50.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final artisanProvider = Provider.of<ArtisanProvider>(context);
    
    // Trier les artisans
    final sortedArtisans = List.from(artisanProvider.artisans);
    if (_sortBy == 'distance' && _userPosition != null) {
      sortedArtisans.sort((a, b) {
        final distA = GeolocationService.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          a.position.latitude,
          a.position.longitude,
        );
        final distB = GeolocationService.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          b.position.latitude,
          b.position.longitude,
        );
        return distA.compareTo(distB);
      });
    } else if (_sortBy == 'prix') {
      sortedArtisans.sort((a, b) => 
        a.tarifs['tarifHoraire'].compareTo(b.tarifs['tarifHoraire']));
    } else {
      // Tri par note (par défaut)
      sortedArtisans.sort((a, b) => b.noteGlobale.compareTo(a.noteGlobale));
    }

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go(AppRouter.homeClient),
        ),
        title: Text(
          widget.metier ?? 'Recherche d\'artisans',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          // Barre de tri
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Text(
                  'Trier par:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('Note', 'note'),
                        const SizedBox(width: 8),
                        if (_userPosition != null)
                          _buildSortChip('Distance', 'distance'),
                        if (_userPosition != null)
                          const SizedBox(width: 8),
                        _buildSortChip('Prix', 'prix'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des artisans
          Expanded(
            child: artisanProvider.isLoading || _isLoadingPosition
                ? const LoadingWidget(showShimmer: true)
                : RefreshIndicator(
                    onRefresh: _searchArtisans,
                    child: sortedArtisans.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sortedArtisans.length,
                            itemBuilder: (context, index) {
                              final artisan = sortedArtisans[index];
                              final distance = _userPosition != null
                                  ? GeolocationService.calculateDistance(
                                      _userPosition!.latitude,
                                      _userPosition!.longitude,
                                      artisan.position.latitude,
                                      artisan.position.longitude,
                                    )
                                  : null;
                              
                              return ArtisanCard(
                                artisan: artisan,
                                distance: distance,
                                onTap: () {
                                  context.go(
                                    AppRouter.artisanProfile,
                                    extra: artisan,
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.greyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.greyMedium,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.greyDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.greyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun artisan trouvé',
            style: AppTextStyles.h3.copyWith(color: AppColors.greyDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères de recherche',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.greyMedium),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
