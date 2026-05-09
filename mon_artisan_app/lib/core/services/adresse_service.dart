import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/villes_benin.dart';

/// Résultat d'une détection de position.
class AdresseDetectee {
  final GeoPoint position;
  final String adresseComplete; // Lisible par tous
  final String rue;
  final String quartier;
  final String ville;
  final String pays;

  const AdresseDetectee({
    required this.position,
    required this.adresseComplete,
    required this.rue,
    required this.quartier,
    required this.ville,
    required this.pays,
  });
}

class AdresseService {
  /// Détecte la position GPS et retourne une adresse lisible en français.
  ///
  /// Gère automatiquement les permissions.
  /// Lance une [Exception] avec un message clair si la localisation échoue.
  static Future<AdresseDetectee> detecterPosition() async {
    // 1. Vérifier si le service est activé
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'La localisation est désactivée sur votre téléphone.\n'
        'Activez-la dans Paramètres → Localisation.',
      );
    }

    // 2. Vérifier / demander les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Vous avez refusé l\'accès à votre position.\n'
          'Autorisez l\'application dans les paramètres.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'L\'accès à la localisation est bloqué.\n'
        'Allez dans Paramètres → Applications → Mon Artisan → Autorisations.',
      );
    }

    // 3. Obtenir la position GPS
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );

    // 4. Convertir en adresse lisible
    return _positionEnAdresse(position);
  }

  /// Convertit une [Position] GPS en [AdresseDetectee] lisible.
  static Future<AdresseDetectee> _positionEnAdresse(Position position) async {
    final geoPoint = GeoPoint(position.latitude, position.longitude);

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Construire les composants de l'adresse
        final rue = _construireRue(p);
        final quartier = _trouverQuartier(p);
        final ville = _trouverVille(p);
        final pays = p.country ?? 'Bénin';

        // Adresse complète lisible
        final adresseComplete = _construireAdresseComplete(
          rue: rue,
          quartier: quartier,
          ville: ville,
          pays: pays,
        );

        return AdresseDetectee(
          position: geoPoint,
          adresseComplete: adresseComplete,
          rue: rue,
          quartier: quartier,
          ville: ville,
          pays: pays,
        );
      }
    } catch (_) {
      // Geocoding échoué (réseau lent) → adresse approximative
    }

    // Fallback : coordonnées brutes formatées lisiblement
    return AdresseDetectee(
      position: geoPoint,
      adresseComplete:
          'Position détectée (${position.latitude.toStringAsFixed(4)}°N, '
          '${position.longitude.toStringAsFixed(4)}°E)',
      rue: '',
      quartier: '',
      ville: '',
      pays: 'Bénin',
    );
  }

  /// Construit la partie "rue" de l'adresse.
  static String _construireRue(Placemark p) {
    final parts = <String>[];
    if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
      parts.add(p.thoroughfare!);
    }
    if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) {
      parts.add('N° ${p.subThoroughfare}');
    }
    return parts.join(', ');
  }

  /// Trouve le quartier le plus précis disponible.
  static String _trouverQuartier(Placemark p) {
    // Priorité : subLocality > locality si subLocality est vide
    if (p.subLocality != null && p.subLocality!.isNotEmpty) {
      return p.subLocality!;
    }
    if (p.locality != null && p.locality!.isNotEmpty) {
      return p.locality!;
    }
    if (p.subAdministrativeArea != null &&
        p.subAdministrativeArea!.isNotEmpty) {
      return p.subAdministrativeArea!;
    }
    return '';
  }

  /// Trouve la ville.
  static String _trouverVille(Placemark p) {
    // Essayer de matcher avec nos villes connues
    final candidates = [
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
    ].whereType<String>().where((s) => s.isNotEmpty);

    for (final candidate in candidates) {
      final match = findVille(candidate);
      if (match != null) return match;
    }

    // Retourner la locality brute si pas de match
    return p.locality ?? p.subAdministrativeArea ?? '';
  }

  /// Construit une adresse complète lisible et humaine.
  static String _construireAdresseComplete({
    required String rue,
    required String quartier,
    required String ville,
    required String pays,
  }) {
    final parts = <String>[];

    if (rue.isNotEmpty) parts.add(rue);
    if (quartier.isNotEmpty) parts.add('Quartier $quartier');
    if (ville.isNotEmpty) parts.add(ville);
    if (pays.isNotEmpty && pays != 'Bénin') parts.add(pays);

    if (parts.isEmpty) return 'Position détectée';

    return parts.join(', ');
  }
}
