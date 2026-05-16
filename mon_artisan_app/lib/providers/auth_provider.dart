import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';
import '../core/constants/metiers_data.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseService.auth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      print('[LOAD] Loading user data for: $userId');
      final doc = await FirebaseService.usersCollection.doc(userId).get();
      if (doc.exists) {
        print('[INFO] Document exists, data: ${doc.data()}');
        _userModel = UserModel.fromFirestore(doc);
        print('[SUCCESS] UserModel created: roles=${_userModel?.roles}, hasAdmin=${_userModel?.hasRole('admin')}');
        notifyListeners();
      } else {
        print('[ERROR] Document does not exist');
      }
    } catch (e) {
      print('[ERROR] Error loading user data: $e');
      _errorMessage = 'Erreur lors du chargement des données utilisateur';
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connexion impossible pour le moment';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    required String ville,
    required String quartier,
    required GeoPoint position,
    String? metier,
    String? metierCategorie,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Créer le compte Firebase Auth
      // Firebase Auth gère nativement les doublons d'email (email-already-in-use)
      final userCredential = await FirebaseService.signUpWithEmail(email, password);
      final userId = userCredential.user!.uid;

      // Vérifier si un document user existe déjà (cas multi-rôle)
      // Cette lecture est autorisée car l'utilisateur est maintenant authentifié
      final existingDoc = await FirebaseService.usersCollection.doc(userId).get();

      if (existingDoc.exists) {
        // Utilisateur existant — ajouter le nouveau rôle
        final existingUser = UserModel.fromFirestore(existingDoc);

        if (existingUser.hasRole(role)) {
          _isLoading = false;
          _errorMessage = 'Vous êtes déjà inscrit avec ce rôle';
          notifyListeners();
          return false;
        }

        final updatedUser = existingUser.copyWithAddedRole(role);
        await FirebaseService.usersCollection
            .doc(userId)
            .update(updatedUser.toFirestore());

        if (role == 'artisan') {
          await _createBasicArtisanProfile(userId, updatedUser, metier: metier, metierCategorie: metierCategorie);
        }
      } else {
        // Nouvel utilisateur — créer le document
        final newUser = UserModel(
          id: userId,
          roles: [role],
          nom: nom,
          prenom: prenom,
          telephone: telephone,
          email: email,
          ville: ville,
          quartier: quartier,
          position: position,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await FirebaseService.usersCollection.doc(userId).set(newUser.toFirestore());

        if (role == 'artisan') {
          await _createBasicArtisanProfile(userId, newUser, metier: metier, metierCategorie: metierCategorie);
        }
      }

      // Charger immédiatement le userModel sans attendre le listener async
      await _loadUserData(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'L\'inscription a échoué. Veuillez réessayer.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Impossible d\'envoyer l\'email de récupération';
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà associé à un compte';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'weak-password':
        return 'Le mot de passe choisi est trop simple';
      case 'network-request-failed':
        return 'Problème de connexion internet';
      case 'too-many-requests':
        return 'Trop de tentatives échouées. Réessayez plus tard.';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      default:
        return 'Une erreur s\'est produite lors de l\'authentification';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Mettre à jour l'utilisateur depuis Firestore
  Future<void> setUserFromFirestore(DocumentSnapshot doc) async {
    if (doc.exists) {
      _userModel = UserModel.fromFirestore(doc);
      notifyListeners();
    }
  }

  // Obtenir le rôle actif de l'utilisateur (pour navigation)
  String? getActiveRole() {
    if (_userModel == null) return null;
    
    // Si l'utilisateur a un seul rôle, retourner ce rôle
    if (_userModel!.roles.length == 1) {
      return _userModel!.roles.first;
    }
    
    // Si l'utilisateur a plusieurs rôles, retourner le premier par défaut
    // (on pourrait aussi sauvegarder le dernier rôle utilisé dans SharedPreferences)
    return _userModel!.roles.first;
  }
  
  // Vérifier si l'utilisateur a plusieurs rôles
  bool hasMultipleRoles() {
    return _userModel != null && _userModel!.roles.length > 1;
  }

  // C8 — Créer un profil artisan de base lors de l'inscription
  // Utilise .set() avec l'UID comme ID de document (pas .add() qui génère un ID aléatoire)
  Future<void> _createBasicArtisanProfile(String userId, UserModel user, {String? metier, String? metierCategorie}) async {
    try {
      String finalMetier = metier ?? 'Artisan';
      String finalCategorie = metierCategorie ?? 'Autres Services Artisanaux';

      // Si la catégorie n'est pas fournie, la déduire depuis metiers_data.dart
      if (metierCategorie == null && metier != null && metier.isNotEmpty) {
        final matches = searchMetiers(metier);
        if (matches.isNotEmpty) {
          finalCategorie = matches.first['categorie']!;
        }
      }

      final artisanData = {
        'userId': userId,
        'metier': finalMetier,
        'metierCategorie': finalCategorie,
        'description': '',
        'experience': 0,
        'tarifs': {'horaire': 5000},
        'disponibilite': false,
        'rayonAction': 10.0,
        'position': user.position,
        'geohash': '',
        'ville': user.ville,
        'quartier': user.quartier,
        'photos': [],
        'certifications': [],
        'noteGlobale': 0.0,
        'nombreAvis': 0,
        'nombreCommandes': 0,
        'revenusTotal': 0.0,
        'revenusDisponibles': 0.0,
        'isVerified': false,
        'verificationStatus': 'pending',
        'isProfileComplete': false,
        'diplome': null,
        'cip': null,
        'cipPhoto': null,
        'atelierPhotos': [],
        'atelierAdresse': null,
        'nom': user.nom,
        'prenom': user.prenom,
        'photoUrl': user.photoUrl,
        'telephone': user.telephone,
        'email': user.email,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      // C8 — Utiliser .set() avec l'UID comme ID de document
      // Cela garantit l'unicité (pas de doublons si l'inscription est appelée deux fois)
      // et permet les règles Firestore basées sur l'ID du document.
      await FirebaseService.firestore
          .collection('artisans')
          .doc(userId) // ← ID = UID Firebase Auth
          .set(artisanData, SetOptions(merge: true)); // merge: true = idempotent
    } catch (e) {
      print('Erreur création profil artisan: $e');
    }
  }
}
