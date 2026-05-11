import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/firebase_service.dart';

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
      _errorMessage = 'Une erreur est survenue';
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
    String? metier, // ✅ Ajout du paramètre métier
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Vérifier si l'utilisateur existe déjà avec cet email
      final existingUserQuery = await FirebaseService.usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        // L'utilisateur existe déjà
        final existingUserDoc = existingUserQuery.docs.first;
        final existingUser = UserModel.fromFirestore(existingUserDoc);
        
        // Vérifier si l'utilisateur a déjà ce rôle
        if (existingUser.hasRole(role)) {
          _isLoading = false;
          _errorMessage = 'Vous êtes déjà inscrit avec ce rôle';
          notifyListeners();
          return false;
        }
        
        // Ajouter le nouveau rôle à l'utilisateur existant
        final updatedUser = existingUser.copyWithAddedRole(role);
        await FirebaseService.usersCollection
            .doc(existingUser.id)
            .update(updatedUser.toFirestore());
        
        // Si le nouveau rôle est artisan, créer le profil artisan
        if (role == 'artisan') {
          await _createBasicArtisanProfile(existingUser.id, updatedUser, metier: metier);
        }
        
        // Si l'utilisateur n'est pas encore connecté, le connecter
        if (_firebaseUser == null) {
          await FirebaseService.signInWithEmail(email, password);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Nouvel utilisateur - créer le compte Firebase Auth
      final userCredential = await FirebaseService.signUpWithEmail(email, password);
      final userId = userCredential.user!.uid;

      final newUser = UserModel(
        id: userId,
        roles: [role], // Premier rôle
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

      // Si c'est un artisan, créer un profil artisan de base
      if (role == 'artisan') {
        await _createBasicArtisanProfile(userId, newUser, metier: metier);
      }

      _userModel = newUser;
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
      _errorMessage = 'Une erreur est survenue';
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
      _errorMessage = 'Erreur lors de la réinitialisation du mot de passe';
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'network-request-failed':
        return 'Erreur de connexion réseau';
      default:
        return 'Une erreur est survenue';
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
  Future<void> _createBasicArtisanProfile(String userId, UserModel user, {String? metier}) async {
    try {
      // Mo6 — Catégories alignées avec metiers_data.dart (10 catégories complètes)
      String finalMetier = metier ?? 'Artisan';
      String metierCategorie = 'Autre';

      if (metier != null && metier.isNotEmpty) {
        const Map<String, List<String>> metiersByCategorie = {
          'BTP & Construction': [
            'Électricien', 'Plombier', 'Maçon', 'Peintre', 'Menuisier',
            'Carreleur', 'Charpentier', 'Soudeur', 'Plafonneur',
            'Serrurier / Métallier', 'Couvreur / Zingueur', 'Vitrier / Miroitier',
            'Poseur de Parquet', 'Poseur Faux-Plafond',
          ],
          'Énergie & Climatisation': [
            'Panneaux Solaires', 'Climatisation', 'Chauffagiste',
            'Installateur Gaz', 'Électricité Industrielle',
          ],
          'Aménagement & Finitions': [
            'Paysagiste', 'Étanchéité', 'Isolation Thermique',
            'Plâtrier / Stucateur', 'Peintre Industriel',
          ],
          'Gros Œuvre': [
            'Démolition', 'Terrassement', 'Béton Armé / Ferrailleur',
            'Coffreur / Bancheur', 'Échafaudeur',
          ],
          'Études & Conception': [
            'Architecte / Dessinateur', 'Bureau d\'étude BTP',
            'Géotechnicien', 'Topographe', 'Expert en Bâtiment',
          ],
          'Équipements & Installations': [
            'Ascensoriste', 'Domotique / Smart Home', 'Alarme / Sécurité',
            'Technicien Fibre Optique',
          ],
          'Eau & Assainissement': [
            'Foreur / Puits', 'Assainissement', 'Construction Piscine',
          ],
          'Services & Maintenance': [
            'Rénovation Générale', 'Nettoyage Chantier',
            'Location Engins BTP', 'Monteur Préfabriqué',
          ],
          'Services à la personne': [
            'Coiffeuse', 'Maquilleuse', 'Esthéticienne', 'Tresse africaine',
            'Femme de ménage', 'Nounou', 'Garde malade',
          ],
          'Événementiel': [
            'Traiteur', 'Pâtissier', 'Décorateur', 'Photographe',
            'Vidéaste', 'DJ', 'Wedding planner',
          ],
          'Réparation': [
            'Mécanicien', 'Carrossier', 'Réparateur téléphone',
          ],
        };

        for (final entry in metiersByCategorie.entries) {
          if (entry.value.contains(metier)) {
            metierCategorie = entry.key;
            break;
          }
        }
      }

      final artisanData = {
        'userId': userId,
        'metier': finalMetier,
        'metierCategorie': metierCategorie,
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
