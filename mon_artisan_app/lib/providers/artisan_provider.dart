import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:io';
import '../models/artisan_model.dart';
import '../models/commande_model.dart';
import '../core/services/firebase_service.dart';

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
        // Ne pas charger les commandes pour éviter l'erreur d'index
        // await _loadCommandes();
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

  // Rechercher des artisans
  Future<void> searchArtisans({
    String? metier,
    String? ville,
    String? quartier,
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query query = FirebaseService.artisansCollection
          .where('disponibilite', isEqualTo: true);

      if (metier != null && metier.isNotEmpty) {
        query = query.where('metier', isEqualTo: metier);
      }

      if (ville != null && ville.isNotEmpty) {
        query = query.where('ville', isEqualTo: ville);
      }

      final querySnapshot = await query
          .orderBy('noteGlobale', descending: true)
          .limit(50)
          .get();

      _artisans = querySnapshot.docs
          .map((doc) => ArtisanModel.fromFirestore(doc))
          .toList();

      // TODO: Filtrer par distance si latitude/longitude fournis
      if (latitude != null && longitude != null) {
        _artisans = _artisans.where((artisan) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            artisan.position.latitude,
            artisan.position.longitude,
          );
          return distance <= radiusKm;
        }).toList();
      }

    } catch (e) {
      _errorMessage = 'Erreur lors de la recherche';
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
      await FirebaseService.commandesCollection
          .doc(commandeId)
          .update({
        'statut': 'annulee',
        'commentaireArtisan': raison,
        'updatedAt': Timestamp.now(),
      });

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

  // Calculer la distance entre deux points (formule Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Nettoyer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Compléter le profil artisan avec documents
  Future<bool> completeArtisanProfile({
    required String userId,
    required String cip,
    required String diplome,
    required List<String> atelierPhotos,
    required String atelierAdresse,
    required String description,
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
      
      // Mettre à jour avec les nouvelles informations
      await FirebaseService.artisansCollection.doc(artisanDoc.id).update({
        'cip': cip,
        'diplome': diplome,
        'atelierPhotos': atelierPhotos,
        'atelierAdresse': atelierAdresse,
        'description': description,
        'isProfileComplete': true,
        'verificationStatus': 'pending',
        'updatedAt': Timestamp.now(),
      });

      // Recharger le profil
      await loadArtisanProfile(userId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du profil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Uploader une image vers Firebase Storage
  Future<String> uploadImage(String filePath, String storagePath) async {
    try {
      final file = File(filePath);
      final ref = FirebaseService.storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erreur upload image: $e');
      throw Exception('Erreur lors du téléchargement de l\'image: $e');
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