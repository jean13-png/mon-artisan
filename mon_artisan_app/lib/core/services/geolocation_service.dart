import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class GeolocationService {
  static const double earthRadius = 6371; // Rayon de la Terre en km

  /// Demander la permission de localisation
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      }
      
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return false;
      }
      
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la demande de permission: $e');
    }
  }

  /// Obtenir la position actuelle
  static Future<Position> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      
      if (!hasPermission) {
        throw Exception('Permission de localisation refusée');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la position: $e');
    }
  }

  /// Obtenir la position actuelle en tant que GeoPoint
  static Future<GeoPoint> getCurrentGeoPoint() async {
    try {
      final position = await getCurrentPosition();
      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du GeoPoint: $e');
    }
  }

  /// Calculer la distance entre deux points (formule Haversine)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Calculer la distance entre deux GeoPoints
  static double calculateDistanceGeoPoint(GeoPoint point1, GeoPoint point2) {
    return calculateDistance(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Convertir les degrés en radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Obtenir l'adresse à partir des coordonnées
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.postalCode} ${place.locality}';
      }

      return '$latitude, $longitude';
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'adresse: $e');
    }
  }

  /// Obtenir les coordonnées à partir d'une adresse
  static Future<GeoPoint?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return GeoPoint(location.latitude, location.longitude);
      }

      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des coordonnées: $e');
    }
  }

  /// Filtrer les artisans par distance
  static List<T> filterByDistance<T>(
    List<T> items,
    double userLat,
    double userLon,
    double radiusKm,
    GeoPoint Function(T) getPosition,
  ) {
    return items.where((item) {
      final position = getPosition(item);
      final distance = calculateDistance(
        userLat,
        userLon,
        position.latitude,
        position.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Trier les artisans par distance
  static List<T> sortByDistance<T>(
    List<T> items,
    double userLat,
    double userLon,
    GeoPoint Function(T) getPosition,
  ) {
    final itemsWithDistance = items.map((item) {
      final position = getPosition(item);
      final distance = calculateDistance(
        userLat,
        userLon,
        position.latitude,
        position.longitude,
      );
      return {'item': item, 'distance': distance};
    }).toList();

    itemsWithDistance.sort((a, b) => (a['distance'] as double)
        .compareTo(b['distance'] as double));

    return itemsWithDistance.map((e) => e['item'] as T).toList();
  }

  /// Générer un geohash pour les requêtes géospatiales
  static String generateGeohash(double latitude, double longitude) {
    // Implémentation simplifiée du geohash
    // Pour une implémentation complète, utiliser le package geoflutterfire_plus
    return '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
  }

  /// Vérifier si la localisation est activée
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Ouvrir les paramètres de localisation
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      throw Exception('Erreur lors de l\'ouverture des paramètres: $e');
    }
  }

  /// Obtenir la distance entre l'utilisateur et un artisan
  static Future<double> getDistanceToArtisan(
    GeoPoint artisanPosition,
  ) async {
    try {
      final userPosition = await getCurrentPosition();
      return calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        artisanPosition.latitude,
        artisanPosition.longitude,
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul de la distance: $e');
    }
  }
}
