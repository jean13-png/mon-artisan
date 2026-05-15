import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  // Firestore
  static FirebaseFirestore get firestore => _firestore;
  
  // Collections
  static CollectionReference get usersCollection => _firestore.collection('users');
  static CollectionReference get artisansCollection => _firestore.collection('artisans');
  static CollectionReference get commandesCollection => _firestore.collection('commandes');
  static CollectionReference get metiersCollection => _firestore.collection('metiers');
  static CollectionReference get avisCollection => _firestore.collection('avis');
  static CollectionReference get notificationsCollection => _firestore.collection('notifications');
  static CollectionReference get villesCollection => _firestore.collection('villes');

  // Storage
  static FirebaseStorage get storage => _storage;
  
  // Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Sign In with Email
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign Up with Email
  static Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Upload Profile Photo
  static Future<String> uploadProfilePhoto(String userId, dynamic file) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      
      // Upload file
      await ref.putFile(file);
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  // Upload Commande Photos
  static Future<List<String>> uploadCommandePhotos(String commandeId, List<dynamic> files) async {
    try {
      final List<String> urls = [];
      
      for (int i = 0; i < files.length; i++) {
        final ref = _storage.ref().child('commande_photos/$commandeId/photo_$i.jpg');
        await ref.putFile(files[i]);
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload des photos: $e');
    }
  }

  // Delete Photo
  static Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la photo: $e');
    }
  }

}
