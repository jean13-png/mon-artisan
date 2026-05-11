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
      Query<ArtisanModel> baseQuery = FirebaseService.artisansCollection.withConverter<ArtisanModel>(
        fromFirestore: (snapshot, _) => ArtisanModel.fromFirestore(snapshot),
        toFirestore: (artisan, _) => artisan.toFirestore(),
      );

      // Appliquer les filtres non-géospatiaux
      if (categorie != null && categorie.isNotEmpty) {
        baseQuery = baseQuery.where('metierCategorie', isEqualTo: categorie);
      }
      if (metier != null && metier.isNotEmpty) {
        baseQuery = baseQuery.where('metier', isEqualTo: metier);
      }
      if (ville != null && ville.isNotEmpty) {
        baseQuery = baseQuery.where('ville', isEqualTo: ville);
      }
      if (quartier != null && quartier.isNotEmpty) {
        baseQuery = baseQuery.where('quartier', isEqualTo: quartier);
      }
      // Exclure les artisans indisponibles
      baseQuery = baseQuery.where('disponibilite', isEqualTo: true);

      List<ArtisanModel> fetchedArtisans = [];

      if (latitude != null && longitude != null) {
        // Recherche géospatiale avec geoflutterfire_plus
        final center = gff.GeoFirePoint(GeoPoint(latitude, longitude));
        final geo = gff.GeoFlutterFire(firestore: FirebaseFirestore.instance);

        final querySnapshot = await geo.collection(collectionRef: baseQuery)
            .near(center: center, radius: radiusKm, field: 'position')
            .get();

        for (var doc in querySnapshot.docs) {
          try {
            final artisan = ArtisanModel.fromFirestore(doc);
            fetchedArtisans.add(artisan);
          } catch (e) {
            print('[ERROR] Erreur parsing artisan ${doc.id} lors de la recherche géospatiale: $e');
          }
        }
        // Trier par distance après la recherche géospatiale
        fetchedArtisans.sort((a, b) {
          final distA = GeolocationService.calculateDistance(latitude, longitude, a.position.latitude, a.position.longitude);
          final distB = GeolocationService.calculateDistance(latitude, longitude, b.position.latitude, b.position.longitude);
          return distA.compareTo(distB);
        });

      } else {
        // Pas de localisation, appliquer uniquement les filtres non-géospatiaux
        final querySnapshot = await baseQuery.get();
        for (var doc in querySnapshot.docs) {
          try {
            final artisan = ArtisanModel.fromFirestore(doc);
            fetchedArtisans.add(artisan);
          } catch (e) {
            print('[ERROR] Erreur parsing artisan ${doc.id} lors de la recherche non-géospatiale: $e');
          }
        }
        // Trier par note globale si pas de localisation
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