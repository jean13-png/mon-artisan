import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/services/geolocation_service.dart';

/// Données de position renvoyées par le MapPickerWidget
class MapPosition {
  final double latitude;
  final double longitude;
  final String adresseComplete;
  final String quartier;
  final String rue;
  final String ville;

  const MapPosition({
    required this.latitude,
    required this.longitude,
    required this.adresseComplete,
    required this.quartier,
    required this.rue,
    required this.ville,
  });
}

/// Widget carte OpenStreetMap interactif.
/// 
/// - Affiche la carte centrée sur la position GPS de l'utilisateur.
/// - Permet de déplacer le marqueur pour ajuster la position.
/// - Affiche l'adresse textuelle en bas.
/// - Gestion propre des erreurs (GPS désactivé, pas d'internet).
class MapPickerWidget extends StatefulWidget {
  /// Position initiale (si déjà connue, évite un appel GPS supplémentaire)
  final double? initialLatitude;
  final double? initialLongitude;

  /// Appelé dès que la position change (drag du marqueur ou centrage GPS)
  final void Function(MapPosition position)? onPositionChanged;

  /// Afficher le bouton "Centrer sur ma position"
  final bool showCenterButton;

  /// Hauteur fixe de la carte (null = expand)
  final double? height;

  const MapPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.onPositionChanged,
    this.showCenterButton = true,
    this.height,
  });

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  final MapController _mapController = MapController();

  ll.LatLng? _markerPosition;
  String _adresseAffichee = 'Détection de votre position...';
  String _quartier = '';
  String _rue = '';
  String _ville = '';
  bool _isLoadingPosition = true;
  bool _isLoadingAddress = false;
  String? _erreur;

  // Position par défaut : Cotonou, Bénin
  static const ll.LatLng _defaultPosition = ll.LatLng(6.3703, 2.3912);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _markerPosition = ll.LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _isLoadingPosition = false;
      _chargerAdresse(_markerPosition!);
    } else {
      _centrerSurPosition();
    }
  }

  Future<void> _centrerSurPosition() async {
    setState(() {
      _isLoadingPosition = true;
      _erreur = null;
    });

    try {
      final pos = await GeolocationService.getCurrentPosition();
      if (!mounted) return;

      final latLng = ll.LatLng(pos.latitude, pos.longitude);
      setState(() {
        _markerPosition = latLng;
        _isLoadingPosition = false;
      });

      // Animer la carte vers la nouvelle position
      _mapController.move(latLng, 16.0);
      await _chargerAdresse(latLng);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPosition = false;
        _markerPosition = _defaultPosition;
        _erreur = e.toString().replaceAll('Exception: ', '');
        _adresseAffichee = 'Position non disponible';
      });
    }
  }

  Future<void> _chargerAdresse(ll.LatLng pos) async {
    if (_isLoadingAddress) return;
    setState(() => _isLoadingAddress = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _quartier = p.subLocality ?? p.locality ?? '';
        _rue = [p.thoroughfare, p.subThoroughfare]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        _ville = p.locality ?? p.administrativeArea ?? '';

        // Construire l'adresse lisible
        final parts = <String>[];
        if (_quartier.isNotEmpty) parts.add(_quartier);
        if (_rue.isNotEmpty) parts.add(_rue);
        if (_ville.isNotEmpty && _ville != _quartier) parts.add(_ville);
        _adresseAffichee = parts.isNotEmpty ? parts.join(', ') : 'Position détectée';
      } else {
        _adresseAffichee = 'Position détectée (adresse non disponible)';
      }
    } catch (_) {
      if (!mounted) return;
      _adresseAffichee = 'Position détectée (adresse hors ligne)';
    }

    if (!mounted) return;
    setState(() => _isLoadingAddress = false);

    // Notifier le parent
    widget.onPositionChanged?.call(MapPosition(
      latitude: pos.latitude,
      longitude: pos.longitude,
      adresseComplete: _adresseAffichee,
      quartier: _quartier,
      rue: _rue,
      ville: _ville,
    ));
  }

  void _onMapTap(TapPosition tapPosition, ll.LatLng latLng) {
    setState(() => _markerPosition = latLng);
    _chargerAdresse(latLng);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // ── Carte ─────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _markerPosition ?? _defaultPosition,
                  initialZoom: 15.0,
                  onTap: _onMapTap,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  // Tuiles OpenStreetMap (gratuites)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.monartisan.app',
                    maxZoom: 19,
                    errorImage: const AssetImage('assets/images/logo_mon_artisan.png'),
                  ),
                  // Marqueur de position
                  if (_markerPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _markerPosition!,
                          width: 50,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.person_pin,
                                    color: AppColors.white, size: 18),
                              ),
                              CustomPaint(
                                painter: _TrianglePainter(AppColors.primaryBlue),
                                size: const Size(14, 8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Indicateur de chargement GPS
              if (_isLoadingPosition)
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryBlue),
                          ),
                          SizedBox(height: 10),
                          Text('Localisation en cours...'),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bouton "Centrer sur ma position"
              if (widget.showCenterButton && !_isLoadingPosition)
                Positioned(
                  top: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'center_map_${widget.key}',
                    onPressed: _centrerSurPosition,
                    backgroundColor: AppColors.white,
                    child: const Icon(Icons.my_location,
                        color: AppColors.primaryBlue),
                  ),
                ),

              // Indicateur OSM en bas à droite
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: AppColors.white.withOpacity(0.7),
                  child: Text(
                    '© OpenStreetMap',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 9),
                  ),
                ),
              ),

              // Conseil tap
              if (!_isLoadingPosition && _erreur == null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app,
                            size: 14, color: AppColors.greyDark),
                        const SizedBox(width: 4),
                        Text(
                          'Appuyez pour ajuster',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.greyDark, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Bandeau adresse ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.white,
          child: _erreur != null
              ? _buildBandeauErreur()
              : _buildBandeauAdresse(),
        ),
      ],
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, child: content);
    }
    return content;
  }

  Widget _buildBandeauAdresse() {
    return Row(
      children: [
        const Icon(Icons.place, color: AppColors.accentRed, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous êtes à :',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.greyDark),
              ),
              const SizedBox(height: 2),
              _isLoadingAddress
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        const SizedBox(width: 8),
                        Text('Récupération de l\'adresse...',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.greyDark)),
                      ],
                    )
                  : Text(
                      _adresseAffichee,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBandeauErreur() {
    return Row(
      children: [
        const Icon(Icons.location_off, color: AppColors.warning, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Position non disponible',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.warning),
              ),
              Text(
                _erreur!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.greyDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _centrerSurPosition,
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}

/// Peint un triangle pointant vers le bas (pointe de marqueur)
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
