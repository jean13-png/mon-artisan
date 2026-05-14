import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'dart:math' as math;

class GeolocationService {

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

  /// Vérifie et demande la permission de localisation, en guidant vers les paramètres si nécessaire.
  static Future<bool> handleLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Localisation désactivée'),
            content: const Text('Le service de localisation est désactivé. Veuillez l\'activer dans vos paramètres.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Paramètres'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission refusée'),
            content: const Text('L\'application a besoin d\'accéder à votre position. Veuillez l\'autoriser dans les paramètres de l\'application.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openAppSettings();
                },
                child: const Text('Paramètres'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    return true;
  }

  /// Obtenir la position actuelle
  static Future<Position> getCurrentPosition() async {
    try {
      // Vérifier si le service de localisation est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Le service de localisation est désactivé. Activez-le dans les paramètres.');
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement. Autorisez l\'accès dans les paramètres.');
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } catch (e) {
      print('[ERROR] Erreur getCurrentPosition: $e');
      rethrow;
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
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    const double p = 0.017453292519943295; // math.pi / 180
    final double a = 0.5 - math.cos((endLat - startLat) * p) / 2 +
        math.cos(startLat * p) * math.cos(endLat * p) *
            (1 - math.cos((endLng - startLng) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
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

  /// Générer un geohash réel via geoflutterfire_plus
  static String generateGeohash(double latitude, double longitude) {
    final point = GeoFirePoint(GeoPoint(latitude, longitude));
    return point.geohash;
  }

  /// Effectuer une recherche géospatiale d'artisans
  /// Note: GeoCollectionReference ne supporte que CollectionReference (pas Query).
  /// Les filtres supplémentaires doivent être appliqués manuellement sur les résultats.
  static Future<List<DocumentSnapshot<Map<String, dynamic>>>> getArtisansNear({
    required CollectionReference<Map<String, dynamic>> collectionRef,
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    String field = 'position',
  }) async {
    final center = GeoFirePoint(GeoPoint(latitude, longitude));
    
    final geoCollection = GeoCollectionReference<Map<String, dynamic>>(collectionRef);

    final docs = await geoCollection.fetchWithin(
      center: center,
      radiusInKm: radiusKm,
      field: field,
      geopointFrom: (data) {
        // Extraire le GeoPoint depuis le champ 'position' du document
        final pos = data[field];
        if (pos is GeoPoint) return pos;
        if (pos is Map) {
          return GeoPoint(
            (pos['latitude'] as num).toDouble(),
            (pos['longitude'] as num).toDouble(),
          );
        }
        return const GeoPoint(0, 0);
      },
    );
    
    return docs;
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
