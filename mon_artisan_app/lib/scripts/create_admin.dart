import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script pour créer le compte administrateur
/// 
/// UTILISATION:
/// 1. Ajouter un bouton temporaire dans l'app qui appelle createAdminAccount()
/// 2. Ou exécuter ce script une seule fois au démarrage
/// 3. Supprimer le code après création du compte

Future<void> createAdminAccount() async {
  try {
    print('🔄 Création du compte administrateur...');
    
    final email = 'tossajean13@gmail.com';
    final password = 'TOSjea13#';
    
    // 1. Créer l'utilisateur dans Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final userId = userCredential.user!.uid;
    print('✅ Utilisateur créé avec UID: $userId');
    
    // 2. Créer le document dans Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'roles': ['admin'],
      'nom': 'TOSSA',
      'prenom': 'Jean',
      'email': email,
      'telephone': '+22997000000',
      'ville': 'Cotonou',
      'quartier': 'Centre',
      'position': GeoPoint(6.3703, 2.3912),
      'isActive': true,
      'contratAccepte': true,
      'paiementInscription': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Document Firestore créé');
    print('');
    print('🎉 COMPTE ADMIN CRÉÉ AVEC SUCCÈS !');
    print('📧 Email: $email');
    print('🔑 Password: $password');
    print('🆔 UID: $userId');
    print('');
    print('⚠️  IMPORTANT: Supprimez ce script après utilisation pour la sécurité !');
    
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      print('⚠️  Le compte existe déjà. Tentative de mise à jour du rôle...');
      
      // Si le compte existe, on met juste à jour le rôle
      try {
        // Se connecter pour obtenir l'UID
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: 'tossajean13@gmail.com',
          password: 'TOSjea13#',
        );
        
        final userId = userCredential.user!.uid;
        
        // Mettre à jour le document
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'roles': FieldValue.arrayUnion(['admin']),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Rôle admin ajouté au compte existant');
        print('🆔 UID: $userId');
        
      } catch (e) {
        print('❌ Erreur lors de la mise à jour: $e');
      }
    } else {
      print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
