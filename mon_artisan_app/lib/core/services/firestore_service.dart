import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/artisan_model.dart';
import '../../models/commande_model.dart';
import '../../models/metier_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get artisans => _firestore.collection('artisans');
  static CollectionReference get commandes => _firestore.collection('commandes');
  static CollectionReference get metiers => _firestore.collection('metiers');
  static CollectionReference get avis => _firestore.collection('avis');
  static CollectionReference get notifications => _firestore.collection('notifications');
  static CollectionReference get villes => _firestore.collection('villes');

  // ==================== USERS ====================

  /// Créer un nouvel utilisateur
  static Future<void> createUser(UserModel user) async {
    try {
      await users.doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  /// Récupérer un utilisateur
  static Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  /// Mettre à jour un utilisateur
  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await users.doc(userId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  // ==================== ARTISANS ====================

  /// Créer un profil artisan
  static Future<void> createArtisan(ArtisanModel artisan) async {
    try {
      await artisans.doc(artisan.id).set(artisan.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la création du profil artisan: $e');
    }
  }

  /// Récupérer un artisan
  static Future<ArtisanModel?> getArtisan(String artisanId) async {
    try {
      final doc = await artisans.doc(artisanId).get();
      if (doc.exists) {
        return ArtisanModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'artisan: $e');
    }
  }

  /// Récupérer l'artisan d'un utilisateur
  static Future<ArtisanModel?> getArtisanByUserId(String userId) async {
    try {
      final querySnapshot = await artisans
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return ArtisanModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'artisan: $e');
    }
  }

  /// Rechercher des artisans par métier et ville
  static Future<List<ArtisanModel>> searchArtisans({
    String? metier,
    String? ville,
    bool disponibleOnly = true,
  }) async {
    try {
      Query query = artisans;

      if (disponibleOnly) {
        query = query.where('disponibilite', isEqualTo: true);
      }

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

      return querySnapshot.docs
          .map((doc) => ArtisanModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'artisans: $e');
    }
  }

  /// Mettre à jour un artisan
  static Future<void> updateArtisan(String artisanId, Map<String, dynamic> data) async {
    try {
      await artisans.doc(artisanId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'artisan: $e');
    }
  }

  /// Marquer l'artisan comme occupé par une commande
  static Future<void> setArtisanBusy(String artisanId, String commandeId) async {
    try {
      await artisans.doc(artisanId).update({
        'disponibilite': false,
        'commandeEnCours': commandeId,
        'raisonIndisponibilite': 'commande_en_cours',
        'dateDebutIndisponibilite': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors du marquage de l\'artisan comme occupé: $e');
    }
  }

  /// Libérer l'artisan (le rendre disponible)
  static Future<void> setArtisanAvailable(String artisanId) async {
    try {
      await artisans.doc(artisanId).update({
        'disponibilite': true,
        'commandeEnCours': null,
        'raisonIndisponibilite': null,
        'dateFinIndisponibilite': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la libération de l\'artisan: $e');
    }
  }

  // ==================== COMMANDES ====================

  /// Créer une commande
  static Future<String> createCommande(CommandeModel commande) async {
    try {
      final docRef = await commandes.add(commande.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  /// Récupérer une commande
  static Future<CommandeModel?> getCommande(String commandeId) async {
    try {
      final doc = await commandes.doc(commandeId).get();
      if (doc.exists) {
        return CommandeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la commande: $e');
    }
  }

  /// Récupérer les commandes d'un client
  static Future<List<CommandeModel>> getCommandesClient(String clientId) async {
    try {
      final querySnapshot = await commandes
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commandes: $e');
    }
  }

  /// Récupérer les commandes d'un artisan
  static Future<List<CommandeModel>> getCommandesArtisan(String artisanId) async {
    try {
      final querySnapshot = await commandes
          .where('artisanId', isEqualTo: artisanId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des commandes: $e');
    }
  }

  /// Mettre à jour une commande
  static Future<void> updateCommande(String commandeId, Map<String, dynamic> data) async {
    try {
      await commandes.doc(commandeId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la commande: $e');
    }
  }

  // ==================== METIERS ====================

  /// Récupérer tous les métiers
  static Future<List<MetierModel>> getAllMetiers() async {
    try {
      final querySnapshot = await metiers
          .where('isActive', isEqualTo: true)
          .orderBy('ordre')
          .get();

      return querySnapshot.docs
          .map((doc) => MetierModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des métiers: $e');
    }
  }

  /// Récupérer les métiers par catégorie
  static Future<List<MetierModel>> getMetiersByCategorie(String categorie) async {
    try {
      final querySnapshot = await metiers
          .where('categorie', isEqualTo: categorie)
          .where('isActive', isEqualTo: true)
          .orderBy('ordre')
          .get();

      return querySnapshot.docs
          .map((doc) => MetierModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des métiers: $e');
    }
  }

  // ==================== VILLES ====================

  /// Récupérer toutes les villes
  static Future<List<String>> getAllVilles() async {
    try {
      final querySnapshot = await villes
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc['nom'] as String)
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des villes: $e');
    }
  }

  /// Récupérer les quartiers d'une ville
  static Future<List<String>> getQuartiers(String ville) async {
    try {
      final querySnapshot = await villes
          .where('nom', isEqualTo: ville)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final quartiers = querySnapshot.docs.first['quartiers'] as List;
        return quartiers.cast<String>();
      }
      return [];
    } catch (e) {
      throw Exception('Erreur lors de la récupération des quartiers: $e');
    }
  }

  // ==================== AVIS ====================

  /// Créer un avis
  static Future<void> createAvis({
    required String commandeId,
    required String artisanId,
    required String clientId,
    required double note,
    required String commentaire,
  }) async {
    try {
      await avis.add({
        'commandeId': commandeId,
        'artisanId': artisanId,
        'clientId': clientId,
        'note': note,
        'commentaire': commentaire,
        'isVisible': true,
        'createdAt': Timestamp.now(),
      });
      
      // Mettre à jour la commande avec la note
      await commandes.doc(commandeId).update({
        'noteClient': note,
        'commentaireClient': commentaire,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'avis: $e');
    }
  }

  /// Mettre à jour la note globale d'un artisan
  static Future<void> updateArtisanRating(String artisanId) async {
    try {
      // Récupérer tous les avis de l'artisan
      final querySnapshot = await avis
          .where('artisanId', isEqualTo: artisanId)
          .where('isVisible', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return;
      }

      // Calculer la moyenne
      double totalNote = 0;
      for (var doc in querySnapshot.docs) {
        totalNote += (doc['note'] as num).toDouble();
      }
      final noteGlobale = totalNote / querySnapshot.docs.length;
      final nombreAvis = querySnapshot.docs.length;

      // Mettre à jour l'artisan
      await artisans.doc(artisanId).update({
        'noteGlobale': noteGlobale,
        'nombreAvis': nombreAvis,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la note: $e');
    }
  }

  /// Récupérer les avis d'un artisan
  static Future<List<Map<String, dynamic>>> getAvisArtisan(String artisanId) async {
    try {
      final querySnapshot = await avis
          .where('artisanId', isEqualTo: artisanId)
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des avis: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Créer une notification
  static Future<void> createNotification(Map<String, dynamic> notification) async {
    try {
      await notifications.add({
        ...notification,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
    } catch (e) {
      throw Exception('Erreur lors de la création de la notification: $e');
    }
  }

  /// Récupérer les notifications d'un utilisateur
  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final querySnapshot = await notifications
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Ajouter l'ID du document
            return data;
          })
          .toList();
    } catch (e) {
      // Si l'index n'existe pas encore, retourner une liste vide
      // au lieu de crasher l'application
      print('Erreur notifications (index manquant?): $e');
      return [];
    }
  }

  /// Marquer une notification comme lue
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la notification: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch update pour plusieurs documents
  static Future<void> batchUpdate(
    String collection,
    List<Map<String, dynamic>> updates,
  ) async {
    try {
      final batch = _firestore.batch();

      for (var update in updates) {
        final docId = update['id'] as String;
        final data = Map<String, dynamic>.from(update)..remove('id');
        batch.update(_firestore.collection(collection).doc(docId), data);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour en batch: $e');
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Transaction pour accepter une commande et mettre à jour les stats artisan
  static Future<void> accepterCommandeTransaction(
    String commandeId,
    String artisanId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Mettre à jour la commande
        transaction.update(
          commandes.doc(commandeId),
          {
            'statut': 'acceptee',
            'acceptedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          },
        );

        // Mettre à jour les stats artisan
        final artisanDoc = await transaction.get(artisans.doc(artisanId));
        if (artisanDoc.exists) {
          final nombreCommandes = (artisanDoc['nombreCommandes'] ?? 0) as int;
          transaction.update(artisans.doc(artisanId), {
            'nombreCommandes': nombreCommandes + 1,
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'acceptation de la commande: $e');
    }
  }
}
