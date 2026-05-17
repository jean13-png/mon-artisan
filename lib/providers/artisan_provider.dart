import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart' as gff;
import 'dart:io';
import '../models/artisan_model.dart';
import '../models/commande_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/cloudinary_service.dart';
import '../core/services/geolocation_service.dart';
import '../core/services/firestore_service.dart';

class ArtisanProvider extends ChangeNotifier {
  ArtisanModel? _currentArtisan;
  List<ArtisanModel> _artisans = [];
  List<CommandeModel> _nouvellesCommandes = [];
  List<CommandeModel> _commandesAcceptees = [];
  List<CommandeModel> _commandesTerminees = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  ArtisanModel? get currentArtisan => _currentArtisan;
  List<ArtisanModel> get artisans => _artisans;
  List<CommandeModel> get nouvellesCommandes => _nouvellesCommandes;
  List<CommandeModel> get commandesAcceptees => _commandesAcceptees;
  List<CommandeModel> get commandesTerminees => _commandesTerminees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger le profil artisan
  Future<void> loadArtisanProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseService.artisansCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _currentArtisan = ArtisanModel.fromFirestore(querySnapshot.docs.first);
        // M2 — Charger les commandes maintenant que l'index est géré en mémoire
        await _loadCommandes();
      } else {
        // Profil artisan non trouvé - créer un profil minimal en mémoire
        _currentArtisan = ArtisanModel(
          id: '',
          userId: userId,
          metier: 'Artisan',
          metierCategorie: 'Autre',
          description: 'Profil à compléter',
          tarifs: {'horaire': 5000},
          experience: 0,
          position: const GeoPoint(6.3703, 2.3912),
          geohash: '',
          ville: 'Cotonou',
          quartier: '',
          noteGlobale: 0,
          nombreAvis: 0,
          nombreCommandes: 0,
          revenusTotal: 0,
          revenusDisponibles: 0,
          disponibilite: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Erreur chargement profil: $e');
      _errorMessage = 'Erreur lors du chargement du profil';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Charger les commandes de l'artisan
  Future<void> _loadCommandes() async {
    if (_currentArtisan == null) return;

    try {
      // Requête simplifiée sans orderBy pour éviter l'erreur d'index
      final querySnapshot = await FirebaseService.commandesCollection
          .where('artisanId', isEqualTo: _currentArtisan!.userId)
          .get();

      final commandes = querySnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();

      // Trier en mémoire
      commandes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _nouvellesCommandes = commandes
          .where((c) => c.statut == 'en_attente')
          .toList();
      
      _commandesAcceptees = commandes
          .where((c) => c.statut == 'acceptee' || c.statut == 'en_cours')
          .toList();
      
      _commandesTerminees = commandes
          .where((c) => c.statut == 'terminee' || c.statut == 'validee')
          .toList();

    } catch (e) {
      print('Erreur chargement commandes: $e');
      _errorMessage = 'Erreur lors du chargement des commandes';
      // Initialiser avec des listes vides en cas d'erreur
      _nouvellesCommandes = [];
      _commandesAcceptees = [];
      _commandesTerminees = [];
    }
  }

  // Rechercher des artisans avec recherche intelligente par rayon
  Future<void> searchArtisans({
    String? metier,
    String? categorie,
    String? ville,
    String? quartier,
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final CollectionReference<Map<String, dynamic>> rawCollection =
          FirebaseService.artisansCollection as CollectionReference<Map<String, dynamic>>;

      List<ArtisanModel> fetchedArtisans = [];

      // Normaliser le terme de recherche (minuscules, sans accents)
      final metierNorm = metier != null ? _normalizeString(metier.trim()) : null;
      final villeNorm = ville != null ? _normalizeString(ville.trim()) : null;
      final quartierNorm = quartier != null ? _normalizeString(quartier.trim()) : null;

      if (latitude != null && longitude != null) {
        // Recherche géospatiale via geoflutterfire_plus
        final center = gff.GeoFirePoint(GeoPoint(latitude, longitude));
        final geoCollection = gff.GeoCollectionReference<Map<String, dynamic>>(rawCollection);

        List<DocumentSnapshot<Map<String, dynamic>>> docs = [];
        try {
          docs = await geoCollection.fetchWithin(
            center: center,
            radiusInKm: radiusKm,
            field: 'position',
            geopointFrom: (data) {
              final pos = data['position'];
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
          print('[SEARCH] Géo: ${docs.length} docs dans le rayon $radiusKm km');
        } catch (geoError) {
          print('[WARNING] Recherche géo échouée ($geoError), fallback query classique');
        }

        // Si la recherche géo retourne 0 (geohash vides ou absents),
        // fallback sur query classique qui filtre par distance en mémoire
        if (docs.isEmpty) {
          print('[SEARCH] Géo vide → fallback query classique + filtre distance mémoire');
          final fallback = await rawCollection.get();
          docs = fallback.docs;
        }

        for (var doc in docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            // Filtre catégorie
            if (categorie != null && categorie.isNotEmpty) {
              final cat = _normalizeString(data['metierCategorie'] ?? '');
              if (!cat.contains(_normalizeString(categorie))) continue;
            }

            // Filtre métier — recherche partielle insensible à la casse et aux accents
            if (metierNorm != null && metierNorm.isNotEmpty) {
              final m = _normalizeString(data['metier'] ?? '');
              if (!m.contains(metierNorm) && !metierNorm.contains(m)) continue;
            }

            // Filtre ville
            if (villeNorm != null && villeNorm.isNotEmpty) {
              final v = _normalizeString(data['ville'] ?? '');
              if (!v.contains(villeNorm)) continue;
            }

            // Filtre quartier
            if (quartierNorm != null && quartierNorm.isNotEmpty) {
              final q = _normalizeString(data['quartier'] ?? '');
              if (!q.contains(quartierNorm)) continue;
            }

            // Filtre distance en mémoire (pour le fallback sans geohash)
            final pos = data['position'];
            if (pos is GeoPoint && pos.latitude != 0 && pos.longitude != 0) {
              final dist = GeolocationService.calculateDistance(
                  latitude, longitude, pos.latitude, pos.longitude);
              if (dist > radiusKm) continue;
            }

            fetchedArtisans.add(ArtisanModel.fromFirestore(doc));
          } catch (e) {
            print('[ERROR] Erreur parsing artisan ${doc.id}: $e');
          }
        }

        // Trier par distance
        fetchedArtisans.sort((a, b) {
          final distA = GeolocationService.calculateDistance(latitude, longitude, a.position.latitude, a.position.longitude);
          final distB = GeolocationService.calculateDistance(latitude, longitude, b.position.latitude, b.position.longitude);
          return distA.compareTo(distB);
        });

        // Si toujours 0 résultats après filtre distance, relancer sans filtre distance
        if (fetchedArtisans.isEmpty) {
          print('[SEARCH] 0 résultats avec filtre distance → recherche sans limite de rayon');
          final fallback2 = await rawCollection.get();
          for (var doc in fallback2.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              if (categorie != null && categorie.isNotEmpty) {
                final cat = _normalizeString(data['metierCategorie'] ?? '');
                if (!cat.contains(_normalizeString(categorie))) continue;
              }
              if (metierNorm != null && metierNorm.isNotEmpty) {
                final m = _normalizeString(data['metier'] ?? '');
                if (!m.contains(metierNorm) && !metierNorm.contains(m)) continue;
              }
              if (villeNorm != null && villeNorm.isNotEmpty) {
                final v = _normalizeString(data['ville'] ?? '');
                if (!v.contains(villeNorm)) continue;
              }
              fetchedArtisans.add(ArtisanModel.fromFirestore(doc));
            } catch (e) {
              print('[ERROR] $e');
            }
          }
          print('[SEARCH] Sans limite rayon: ${fetchedArtisans.length} résultats');
          fetchedArtisans.sort((a, b) {
            final distA = GeolocationService.calculateDistance(latitude, longitude, a.position.latitude, a.position.longitude);
            final distB = GeolocationService.calculateDistance(latitude, longitude, b.position.latitude, b.position.longitude);
            return distA.compareTo(distB);
          });
        }

      } else {
        // Pas de localisation → query Firestore classique
        // On récupère tout et on filtre en mémoire pour gérer
        // les accents, casse et variations de noms de champs
        Query<Map<String, dynamic>> query = rawCollection;

        // Filtre ville côté Firestore si fourni (champ exact)
        if (ville != null && ville.isNotEmpty) {
          query = query.where('ville', isEqualTo: ville);
        }

        final querySnapshot = await query.get();
        print('[SEARCH] Classique: ${querySnapshot.docs.length} docs Firestore');

        for (var doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            // Filtre catégorie en mémoire (insensible aux accents)
            if (categorie != null && categorie.isNotEmpty) {
              final cat = _normalizeString(data['metierCategorie'] ?? '');
              if (!cat.contains(_normalizeString(categorie))) continue;
            }

            // Filtre métier en mémoire (insensible à la casse et aux accents)
            if (metierNorm != null && metierNorm.isNotEmpty) {
              final m = _normalizeString(data['metier'] ?? '');
              if (!m.contains(metierNorm) && !metierNorm.contains(m)) continue;
            }

            // Filtre quartier en mémoire
            if (quartierNorm != null && quartierNorm.isNotEmpty) {
              final q = _normalizeString(data['quartier'] ?? '');
              if (!q.contains(quartierNorm)) continue;
            }

            fetchedArtisans.add(ArtisanModel.fromFirestore(doc));
          } catch (e) {
            print('[ERROR] Erreur parsing artisan ${doc.id}: $e');
          }
        }

        fetchedArtisans.sort((a, b) => b.noteGlobale.compareTo(a.noteGlobale));
      }

      _artisans = fetchedArtisans;
      print('[SEARCH] Artisans trouvés: ${_artisans.length}');

    } catch (e) {
      print('Erreur recherche artisans: $e');
      _errorMessage = 'Erreur lors de la recherche: $e';
      _artisans = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mettre à jour la disponibilité
  Future<void> updateDisponibilite(bool disponible) async {
    if (_currentArtisan == null) return;

    try {
      await FirestoreService.updateArtisan(_currentArtisan!.id, {'disponibilite': disponible});

      _currentArtisan = ArtisanModel(
        id: _currentArtisan!.id,
        userId: _currentArtisan!.userId,
        metier: _currentArtisan!.metier,
        metierCategorie: _currentArtisan!.metierCategorie,
        description: _currentArtisan!.description,
        experience: _currentArtisan!.experience,
        tarifs: _currentArtisan!.tarifs,
        disponibilite: disponible,
        rayonAction: _currentArtisan!.rayonAction,
        position: _currentArtisan!.position,
        geohash: _currentArtisan!.geohash,
        ville: _currentArtisan!.ville,
        quartier: _currentArtisan!.quartier,
        photos: _currentArtisan!.photos,
        certifications: _currentArtisan!.certifications,
        noteGlobale: _currentArtisan!.noteGlobale,
        nombreAvis: _currentArtisan!.nombreAvis,
        nombreCommandes: _currentArtisan!.nombreCommandes,
        revenusTotal: _currentArtisan!.revenusTotal,
        revenusDisponibles: _currentArtisan!.revenusDisponibles,
        isVerified: _currentArtisan!.isVerified,
        createdAt: _currentArtisan!.createdAt,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour';
      notifyListeners();
    }
  }

  // Accepter une commande
  Future<bool> accepterCommande(String commandeId) async {
    try {
      await FirebaseService.commandesCollection
          .doc(commandeId)
          .update({
        'statut': 'acceptee',
        'acceptedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Recharger les commandes
      await _loadCommandes();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'acceptation';
      notifyListeners();
      return false;
    }
  }

  // Refuser une commande
  Future<bool> refuserCommande(String commandeId, String? raison) async {
    try {
      // Récupérer la commande pour libérer l'artisan
      final commandeDoc = await FirebaseService.commandesCollection
          .doc(commandeId)
          .get();

      if (commandeDoc.exists) {
        final data = commandeDoc.data() as Map<String, dynamic>;
        final artisanUserId = data['artisanId'] as String? ?? '';

        await FirebaseService.commandesCollection
            .doc(commandeId)
            .update({
          'statut': 'annulee',
          'commentaireArtisan': raison,
          'updatedAt': Timestamp.now(),
        });

        // ✅ Libérer l'artisan via le service centralisé
        if (artisanUserId.isNotEmpty) {
          await FirestoreService.setArtisanAvailable(artisanUserId);
        }
      }

      // Recharger les commandes
      await _loadCommandes();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors du refus';
      notifyListeners();
      return false;
    }
  }

  // Marquer une commande comme terminée
  Future<bool> terminerCommande(String commandeId) async {
    try {
      await FirebaseService.commandesCollection
          .doc(commandeId)
          .update({
        'statut': 'terminee',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Recharger les commandes
      await _loadCommandes();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la finalisation';
      notifyListeners();
      return false;
    }
  }

  // M1 — Déléguer à GeolocationService (source unique de vérité)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return GeolocationService.calculateDistance(lat1, lon1, lat2, lon2);
  }

  // Nettoyer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Compléter le profil artisan avec documents et géolocalisation
  Future<bool> completeArtisanProfile({
    required String userId,
    required String metier,
    required String metierCategorie,
    required String cip,
    required String cipPhoto,
    required String diplome,
    required List<String> atelierPhotos,
    required String atelierAdresse,
    required String description,
    required String ville,
    required String quartier,
    Position? position,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Trouver le profil artisan existant
      final querySnapshot = await FirebaseService.artisansCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _errorMessage = 'Profil artisan introuvable';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final artisanDoc = querySnapshot.docs.first;
      
      // Utiliser la position fournie ou géolocaliser l'adresse
      GeoPoint? geoPosition;
      
      if (position != null) {
        // Utiliser la position GPS actuelle
        geoPosition = GeoPoint(position.latitude, position.longitude);
        print('[SUCCESS] Position GPS utilisée: ${position.latitude}, ${position.longitude}');
      } else {
        // Géolocaliser l'adresse
        try {
          print('[INFO] Géolocalisation de l\'adresse: $atelierAdresse');
          final locations = await locationFromAddress(atelierAdresse);
          
          if (locations.isNotEmpty) {
            final location = locations.first;
            geoPosition = GeoPoint(location.latitude, location.longitude);
            print('[SUCCESS] Position trouvée: ${location.latitude}, ${location.longitude}');
          }
        } catch (e) {
          print('[WARNING] Erreur géolocalisation: $e');
          // Position par défaut (centre de la ville)
          geoPosition = const GeoPoint(6.3703, 2.3912);
        }
      }
      
      // Calculer le geohash
      String geohash = '';
      if (geoPosition != null) {
        geohash = _generateGeohash(geoPosition.latitude, geoPosition.longitude);
      }
      
      // Mettre à jour avec les nouvelles informations
      await FirebaseService.artisansCollection.doc(artisanDoc.id).update({
        'metier': metier,
        'metierCategorie': metierCategorie,
        'cip': cip,
        'cipPhoto': cipPhoto,
        'diplome': diplome,
        'atelierPhotos': atelierPhotos,
        'atelierAdresse': atelierAdresse,
        'description': description,
        'position': geoPosition,
        'ville': ville,
        'quartier': quartier,
        'geohash': geohash,
        'isProfileComplete': true,
        'isVerified': false,
        'verificationStatus': 'pending',
        'updatedAt': Timestamp.now(),
      });

      print('[SUCCESS] Profil artisan mis à jour avec succès');

      // Notifier l'admin qu'un nouveau profil est à valider
      await FirebaseService.firestore.collection('notifications').add({
        'userId': 'admin',
        'titre': 'Nouveau profil à valider',
        'message': 'Un artisan a soumis son profil pour validation.',
        'type': 'nouveau_profil',
        'artisanId': artisanDoc.id,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      
      // Recharger le profil
      await loadArtisanProfile(userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[ERROR] Erreur mise à jour profil: $e');
      _errorMessage = 'Erreur lors de la mise à jour du profil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Générer un geohash réel via geoflutterfire_plus
  String _generateGeohash(double lat, double lon) {
    final point = gff.GeoFirePoint(GeoPoint(lat, lon));
    return point.geohash;
  }
  
  // Normaliser une chaîne (enlever accents, mettre en minuscules)
  String _normalizeString(String str) {
    return str
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c');
  }

  // Mettre à jour la position GPS actuelle de l'artisan
  Future<bool> updateLocation() async {
    if (_currentArtisan == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('[INFO] Mise à jour de la position pour ${_currentArtisan!.userId}');
      
      // 1. Obtenir la position actuelle
      final position = await GeolocationService.getCurrentPosition();
      final geoPoint = GeoPoint(position.latitude, position.longitude);
      
      // 2. Calculer le nouveau geohash
      final geohash = _generateGeohash(position.latitude, position.longitude);
      
      // 3. Mettre à jour Firestore
      await FirebaseService.artisansCollection
          .doc(_currentArtisan!.id)
          .update({
        'position': geoPoint,
        'geohash': geohash,
        'locationUpdatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // 4. Mettre à jour localement
      _currentArtisan = _currentArtisan!.copyWith(
        position: geoPoint,
        geohash: geohash,
        locationUpdatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('[SUCCESS] Position mise à jour : ${position.latitude}, ${position.longitude}');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[ERROR] Erreur updateLocation: $e');
      _errorMessage = 'Impossible de mettre à jour votre position. Vérifiez votre GPS.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Uploader une image vers Cloudinary
  Future<String> uploadImage(String filePath, String storagePath) async {
    try {
      print('[UPLOAD] Début upload Cloudinary: $storagePath');
      
      final file = File(filePath);
      
      // Vérifier que le fichier existe
      if (!await file.exists()) {
        throw Exception('Fichier introuvable');
      }
      
      // Vérifier la taille du fichier (max 10MB pour Cloudinary)
      final fileSize = await file.length();
      print('[INFO] Taille fichier: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Fichier trop volumineux (max 10MB)');
      }
      
      // Extraire le dossier du storagePath
      // Ex: artisans/userId/diplome/123.jpg -> artisans/userId/diplome
      final folder = storagePath.substring(0, storagePath.lastIndexOf('/'));
      print('[INFO] Dossier Cloudinary: $folder');
      
      // Upload vers Cloudinary
      final downloadUrl = await CloudinaryService.uploadImage(filePath, folder);
      print('[SUCCESS] URL obtenue: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('[ERROR] Erreur upload: $e');
      
      // Messages d'erreur simplifiés
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw Exception('Pas de connexion internet');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Délai dépassé. Réessayez.');
      } else {
        throw Exception('Erreur upload. Réessayez.');
      }
    }
  }

  // Réinitialiser les données
  void reset() {
    _currentArtisan = null;
    _artisans = [];
    _nouvellesCommandes = [];
    _commandesAcceptees = [];
    _commandesTerminees = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}