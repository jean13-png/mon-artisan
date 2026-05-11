import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'dart:io';
import '../models/artisan_model.dart';
import '../models/commande_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/cloudinary_service.dart';
import '../core/services/geolocation_service.dart';

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
      // C8 — Utilisation directe de l'ID de document (UID)
      final doc = await FirebaseService.artisansCollection.doc(userId).get();

      if (doc.exists) {
        _currentArtisan = ArtisanModel.fromFirestore(doc);
        await _loadCommandes();
      } else {
        // Fallback si l'ID n'est pas l'UID (migration ou ancien profil)
        final querySnapshot = await FirebaseService.artisansCollection
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          _currentArtisan = ArtisanModel.fromFirestore(querySnapshot.docs.first);
          await _loadCommandes();
        } else {
          // Profil non trouvé...
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
      // RECHERCHE FLEXIBLE: Récupérer TOUS les artisans et filtrer en mémoire
      print('[SEARCH] Récupération de tous les artisans...');
      
      final querySnapshot = await FirebaseService.artisansCollection.get();
      
      print('[SEARCH] Total documents: ${querySnapshot.docs.length}');

      List<ArtisanModel> allArtisans = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('[SEARCH] Document ${doc.id}: metier=${data['metier']}, ville=${data['ville']}');
          
          final artisan = ArtisanModel.fromFirestore(doc);

          // Filtrer par catégorie
          if (categorie != null && categorie.isNotEmpty) {
            final catNorm = _normalizeString(categorie);
            final artisanCatNorm = _normalizeString(artisan.metierCategorie);
            if (!artisanCatNorm.contains(catNorm)) continue;
          }

          // Filtrer par métier ou query (insensible à la casse et aux accents)
          if (metier != null && metier.isNotEmpty) {
            final metierNormalized = _normalizeString(metier);
            final artisanMetierNormalized = _normalizeString(artisan.metier);
            if (!artisanMetierNormalized.contains(metierNormalized)) continue;
          }

          // Filtrer par ville (insensible à la casse)
          if (ville != null && ville.isNotEmpty) {
            if (!artisan.ville.toLowerCase().contains(ville.toLowerCase())) {
              continue;
            }
          }

          // Filtrer par quartier
          if (quartier != null && quartier.isNotEmpty) {
            if (!artisan.quartier.toLowerCase().contains(quartier.toLowerCase())) {
              continue;
            }
          }

          // Exclure les artisans indisponibles
          if (!artisan.estRealementDisponible) continue;

          allArtisans.add(artisan);
        } catch (e) {
          print('[ERROR] Erreur parsing artisan ${doc.id}: $e');
        }
      }
      
      print('[SEARCH] Artisans après filtrage: ${allArtisans.length}');

      // Recherche intelligente par rayon (comme Gozem/Yango)
      if (latitude != null && longitude != null) {
        // Calculer la distance pour chaque artisan
        List<Map<String, dynamic>> artisansWithDistance = allArtisans.map((artisan) {
          final distance = GeolocationService.calculateDistance(
            latitude,
            longitude,
            artisan.position.latitude,
            artisan.position.longitude,
          );
          return {
            'artisan': artisan,
            'distance': distance,
          };
        }).toList();

        // Trier par distance
        artisansWithDistance.sort((a, b) => 
          (a['distance'] as double).compareTo(b['distance'] as double));

        // Recherche par rayon progressif
        List<ArtisanModel> nearbyArtisans = [];
        
        // 1. D'abord chercher dans 5km
        nearbyArtisans = artisansWithDistance
            .where((item) => (item['distance'] as double) <= 5.0)
            .map((item) => item['artisan'] as ArtisanModel)
            .toList();
        
        // 2. Si moins de 3 résultats, élargir à 10km
        if (nearbyArtisans.length < 3) {
          nearbyArtisans = artisansWithDistance
              .where((item) => (item['distance'] as double) <= 10.0)
              .map((item) => item['artisan'] as ArtisanModel)
              .toList();
        }
        
        // 3. Si toujours moins de 3, élargir à 20km
        if (nearbyArtisans.length < 3) {
          nearbyArtisans = artisansWithDistance
              .where((item) => (item['distance'] as double) <= 20.0)
              .map((item) => item['artisan'] as ArtisanModel)
              .toList();
        }
        
        // 4. Si toujours pas assez, prendre tous ceux de la ville (max 50km)
        if (nearbyArtisans.length < 3) {
          nearbyArtisans = artisansWithDistance
              .where((item) => (item['distance'] as double) <= 50.0)
              .map((item) => item['artisan'] as ArtisanModel)
              .toList();
        }
        
        _artisans = nearbyArtisans;
        
        print('[SEARCH] Recherche intelligente:');
        print('  - Artisans dans 5km: ${artisansWithDistance.where((i) => (i['distance'] as double) <= 5.0).length}');
        print('  - Artisans dans 10km: ${artisansWithDistance.where((i) => (i['distance'] as double) <= 10.0).length}');
        print('  - Artisans dans 20km: ${artisansWithDistance.where((i) => (i['distance'] as double) <= 20.0).length}');
        print('  - Total affichés: ${_artisans.length}');
      } else {
        // Pas de localisation, afficher tous les artisans de la ville
        _artisans = allArtisans;
        // Trier par note globale
        _artisans.sort((a, b) => b.noteGlobale.compareTo(a.noteGlobale));
      }

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
      await FirebaseService.artisansCollection
          .doc(_currentArtisan!.id)
          .update({'disponibilite': disponible});

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

        // ✅ Libérer l'artisan
        if (artisanUserId.isNotEmpty) {
          final artisanQuery = await FirebaseService.artisansCollection
              .where('userId', isEqualTo: artisanUserId)
              .where('commandeEnCours', isEqualTo: commandeId)
              .limit(1)
              .get();

          if (artisanQuery.docs.isNotEmpty) {
            await artisanQuery.docs.first.reference.update({
              'disponibilite': true,
              'commandeEnCours': null,
              'raisonIndisponibilite': null,
              'dateFinIndisponibilite': Timestamp.now(),
            });
          }
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
    final point = GeoFirePoint(GeoPoint(lat, lon));
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