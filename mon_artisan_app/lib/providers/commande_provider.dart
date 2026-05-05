import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commande_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/notification_service.dart';

class CommandeProvider extends ChangeNotifier {
  List<CommandeModel> _commandes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CommandeModel> get commandes => _commandes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Créer une nouvelle commande
  Future<String?> createCommande({
    required String clientId,
    required String artisanId,
    required String metier,
    required String description,
    required String adresse,
    required GeoPoint position,
    required String ville,
    required String quartier,
    required DateTime dateIntervention,
    required String heureIntervention,
    required double montant,
    List<String> photos = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Calculer la commission (10%)
      final commission = montant * 0.10;
      final montantArtisan = montant - commission;

      final newCommande = CommandeModel(
        id: '', // Sera généré par Firestore
        clientId: clientId,
        artisanId: artisanId,
        metier: metier,
        description: description,
        adresse: adresse,
        position: position,
        ville: ville,
        quartier: quartier,
        dateIntervention: dateIntervention,
        heureIntervention: heureIntervention,
        statut: 'en_attente',
        montant: montant,
        commission: commission,
        montantArtisan: montantArtisan,
        paiementStatut: 'en_attente',
        photos: photos,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await FirebaseService.firestore
          .collection('commandes')
          .add(newCommande.toFirestore());

      // Créer une notification pour l'artisan
      await FirestoreService.createNotification({
        'userId': artisanId,
        'type': 'nouvelle_commande',
        'titre': 'Nouvelle commande !',
        'message': 'Vous avez reçu une nouvelle commande pour $metier',
        'data': {
          'commandeId': docRef.id,
          'metier': metier,
          'montant': montant,
        },
      });

      _isLoading = false;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de la création de la commande: $e';
      notifyListeners();
      return null;
    }
  }

  // Récupérer les commandes d'un client
  Future<void> loadClientCommandes(String clientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseService.firestore
          .collection('commandes')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      _commandes = querySnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des commandes';
      notifyListeners();
    }
  }

  // Récupérer les commandes d'un artisan
  Future<void> loadArtisanCommandes(String artisanId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseService.firestore
          .collection('commandes')
          .where('artisanId', isEqualTo: artisanId)
          .orderBy('createdAt', descending: true)
          .get();

      _commandes = querySnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des commandes';
      notifyListeners();
    }
  }

  // Mettre à jour le statut d'une commande
  Future<bool> updateCommandeStatut(String commandeId, String newStatut) async {
    try {
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': newStatut,
        'updatedAt': Timestamp.now(),
      });

      // Mettre à jour localement
      final index = _commandes.indexWhere((c) => c.id == commandeId);
      if (index != -1) {
        _commandes[index] = _commandes[index].copyWith(
          statut: newStatut,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du statut';
      notifyListeners();
      return false;
    }
  }

  // Accepter une commande (artisan)
  Future<bool> accepterCommande(String commandeId) async {
    try {
      // Récupérer la commande pour obtenir le clientId
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .get();
      
      if (!commandeDoc.exists) {
        _errorMessage = 'Commande introuvable';
        notifyListeners();
        return false;
      }
      
      final commande = CommandeModel.fromFirestore(commandeDoc);
      
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': 'acceptee',
        'acceptedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour le client
      await FirestoreService.createNotification({
        'userId': commande.clientId,
        'type': 'commande_acceptee',
        'titre': 'Commande acceptée',
        'message': 'Votre commande a été acceptée par l\'artisan',
        'data': {
          'commandeId': commandeId,
          'metier': commande.metier,
        },
      });

      // Notification locale
      await NotificationService.showCommandeAcceptedNotification(
        artisanName: 'L\'artisan',
      );

      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'acceptation de la commande';
      notifyListeners();
      return false;
    }
  }

  // Refuser une commande (artisan)
  Future<bool> refuserCommande(String commandeId) async {
    try {
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': 'annulee',
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors du refus de la commande';
      notifyListeners();
      return false;
    }
  }

  // Marquer une commande comme terminée (artisan)
  Future<bool> terminerCommande(String commandeId) async {
    try {
      // Récupérer la commande pour obtenir le clientId
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .get();
      
      if (!commandeDoc.exists) {
        _errorMessage = 'Commande introuvable';
        notifyListeners();
        return false;
      }
      
      final commande = CommandeModel.fromFirestore(commandeDoc);
      
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': 'terminee',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour le client
      await FirestoreService.createNotification({
        'userId': commande.clientId,
        'type': 'commande_terminee',
        'titre': 'Prestation terminée',
        'message': 'L\'artisan a terminé votre prestation. N\'oubliez pas de le noter !',
        'data': {
          'commandeId': commandeId,
          'metier': commande.metier,
        },
      });

      // Notification locale
      await NotificationService.showPrestationCompletedNotification(
        artisanName: 'L\'artisan',
      );

      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la finalisation de la commande';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Valider une prestation (client) - Débloquer le paiement
  Future<bool> validerPrestation(String commandeId) async {
    try {
      // Récupérer la commande
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .get();
      
      if (!commandeDoc.exists) {
        _errorMessage = 'Commande introuvable';
        notifyListeners();
        return false;
      }
      
      final commande = CommandeModel.fromFirestore(commandeDoc);
      
      // Mettre à jour le statut de paiement et débloquer l'argent
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': 'validee',
        'paiementStatut': 'debloque',
        'dateValidationClient': Timestamp.now(),
        'dateDeblocagePaiement': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Créditer le portefeuille de l'artisan
      await _crediterArtisan(commande.artisanId, commande.montantArtisan);

      // Créer une notification pour l'artisan
      await FirestoreService.createNotification({
        'userId': commande.artisanId,
        'type': 'paiement_debloque',
        'titre': 'Paiement débloqué !',
        'message': 'Le client a validé la prestation. ${commande.montantArtisan.toStringAsFixed(0)} FCFA ont été crédités sur votre portefeuille.',
        'data': {
          'commandeId': commandeId,
          'montant': commande.montantArtisan,
        },
      });

      // Recharger les commandes
      await loadClientCommandes(commande.clientId);
      
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la validation: $e';
      notifyListeners();
      return false;
    }
  }

  // Créditer le portefeuille de l'artisan
  Future<void> _crediterArtisan(String artisanId, double montant) async {
    try {
      // Récupérer le profil artisan
      final artisanQuery = await FirebaseService.firestore
          .collection('artisans')
          .where('userId', isEqualTo: artisanId)
          .limit(1)
          .get();

      if (artisanQuery.docs.isNotEmpty) {
        final artisanDoc = artisanQuery.docs.first;
        final currentRevenus = (artisanDoc.data()['revenusDisponibles'] ?? 0.0).toDouble();
        final currentTotal = (artisanDoc.data()['revenusTotal'] ?? 0.0).toDouble();

        await FirebaseService.firestore
            .collection('artisans')
            .doc(artisanDoc.id)
            .update({
          'revenusDisponibles': currentRevenus + montant,
          'revenusTotal': currentTotal + montant,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Erreur lors du crédit artisan: $e');
    }
  }

  // Rembourser le client (si artisan n'honore pas)
  Future<bool> rembourserClient(String commandeId, String raison) async {
    try {
      // Récupérer la commande
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .get();
      
      if (!commandeDoc.exists) {
        _errorMessage = 'Commande introuvable';
        notifyListeners();
        return false;
      }
      
      final commande = CommandeModel.fromFirestore(commandeDoc);
      
      // Mettre à jour le statut
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': 'annulee',
        'paiementStatut': 'rembourse',
        'commentaireArtisan': raison,
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour le client
      await FirestoreService.createNotification({
        'userId': commande.clientId,
        'type': 'remboursement',
        'titre': 'Remboursement effectué',
        'message': 'Votre commande a été annulée et vous avez été remboursé de ${commande.montant.toStringAsFixed(0)} FCFA.',
        'data': {
          'commandeId': commandeId,
          'montant': commande.montant,
        },
      });

      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors du remboursement: $e';
      notifyListeners();
      return false;
    }
  }
}