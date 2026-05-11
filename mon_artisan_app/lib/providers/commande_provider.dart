import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/commande_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/cloudinary_service.dart';
import '../core/services/geolocation_service.dart';

class CommandeProvider extends ChangeNotifier {
  List<CommandeModel> _commandes = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Système d'idempotence - Verrouillage des opérations
  final Set<String> _operationsEnCours = {};

  List<CommandeModel> get commandes => _commandes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Vérifier si une opération est déjà en cours
  bool _isOperationInProgress(String operationKey) {
    return _operationsEnCours.contains(operationKey);
  }
  
  // Verrouiller une opération
  void _lockOperation(String operationKey) {
    _operationsEnCours.add(operationKey);
  }
  
  // Déverrouiller une opération
  void _unlockOperation(String operationKey) {
    _operationsEnCours.remove(operationKey);
  }

  // Créer une nouvelle commande
  Future<String?> createCommande({
    required String clientId,
    required String artisanId,
    required String metier,
    String typeCommande = 'panne_connue',
    String titre = '',
    required String description,
    required String adresse,
    required GeoPoint position,
    required String ville,
    required String quartier,
    required DateTime dateIntervention,
    required String heureIntervention,
    required double montant,
    double? fraisDeplacement,
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
        typeCommande: typeCommande,
        titre: titre,
        description: description,
        adresse: adresse,
        position: position,
        ville: ville,
        quartier: quartier,
        dateIntervention: dateIntervention,
        heureIntervention: heureIntervention,
        statut: typeCommande == 'diagnostic_requis' ? 'diagnostic_demande' : 'en_attente',
        montant: montant,
        fraisDeplacement: fraisDeplacement,
        fraisDeplacementPayes: false,
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

      // Marquer l'artisan comme indisponible IMMÉDIATEMENT
      await FirestoreService.setArtisanBusy(artisanId, docRef.id);

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
      // Requête simplifiée sans orderBy pour éviter l'erreur d'index
      final querySnapshot = await FirebaseService.firestore
          .collection('commandes')
          .where('clientId', isEqualTo: clientId)
          .get();

      _commandes = querySnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();
      
      // Trier en mémoire par date de création (plus récent en premier)
      _commandes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[ERROR] Erreur chargement commandes client: $e');
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des commandes';
      _commandes = []; // Initialiser avec liste vide en cas d'erreur
      notifyListeners();
    }
  }

  // Récupérer les commandes d'un artisan
  Future<void> loadArtisanCommandes(String artisanId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Requête simplifiée sans orderBy pour éviter l'erreur d'index
      final querySnapshot = await FirebaseService.firestore
          .collection('commandes')
          .where('artisanId', isEqualTo: artisanId)
          .get();

      _commandes = querySnapshot.docs
          .map((doc) => CommandeModel.fromFirestore(doc))
          .toList();
      
      // Trier en mémoire par date de création (plus récent en premier)
      _commandes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[ERROR] Erreur chargement commandes artisan: $e');
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des commandes';
      _commandes = []; // Initialiser avec liste vide en cas d'erreur
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
      // Récupérer la commande pour libérer l'artisan
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
        'statut': 'refusee', // Mo7 — statut distinct de 'annulee' (annulée par le client)
        'updatedAt': Timestamp.now(),
      });

      // ✅ Libérer l'artisan quand il refuse une commande
      await FirestoreService.setArtisanAvailable(commande.artisanId);

      // Notifier le client
      await FirestoreService.createNotification({
        'userId': commande.clientId,
        'type': 'commande_refusee',
        'titre': 'Commande refusée',
        'message': 'L\'artisan n\'est pas disponible pour votre demande.',
        'data': {'commandeId': commandeId},
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
    // ✅ IDEMPOTENCE: Vérifier si l'opération est déjà en cours
    final operationKey = 'valider_$commandeId';
    if (_isOperationInProgress(operationKey)) {
      print('[WARNING] Validation déjà en cours pour $commandeId');
      return false;
    }
    
    // Verrouiller l'opération
    _lockOperation(operationKey);
    
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
      
      // ✅ IDEMPOTENCE: Vérifier si déjà validé
      if (commande.paiementStatut == 'debloque' || commande.statut == 'validee') {
        print('[INFO] Commande déjà validée: $commandeId');
        return true; // Retourner succès car déjà fait
      }
      
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
      
      // Libérer l'artisan IMMÉDIATEMENT
      await FirestoreService.setArtisanAvailable(commande.artisanId);

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
    } finally {
      // ✅ IDEMPOTENCE: Toujours déverrouiller
      _unlockOperation(operationKey);
    }
  }

  // M5 — Créditer le portefeuille de l'artisan de façon atomique
  Future<void> _crediterArtisan(String artisanId, double montant) async {
    try {
      final artisanQuery = await FirebaseService.firestore
          .collection('artisans')
          .where('userId', isEqualTo: artisanId)
          .limit(1)
          .get();

      if (artisanQuery.docs.isNotEmpty) {
        // FieldValue.increment() est atomique — pas de race condition financière
        await FirebaseService.firestore
            .collection('artisans')
            .doc(artisanQuery.docs.first.id)
            .update({
          'revenusDisponibles': FieldValue.increment(montant),
          'revenusTotal': FieldValue.increment(montant),
          'nombreCommandes': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });

        debugPrint('[SUCCESS] Artisan crédité: +${montant.toStringAsFixed(0)} FCFA (atomique)');
      }
    } catch (e) {
      debugPrint('[ERROR] Erreur lors du crédit artisan: $e');
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

      // M10 — Libérer l'artisan lors d'un remboursement
      await FirestoreService.setArtisanAvailable(commande.artisanId);

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

  // Uploader des photos vers Cloudinary
  Future<List<String>> uploadPhotos(List<String> photoPaths, String commandeId) async {
    List<String> uploadedUrls = [];
    
    try {
      for (int i = 0; i < photoPaths.length; i++) {
        final file = File(photoPaths[i]);
        
        if (!await file.exists()) {
          print('[ERROR] Fichier introuvable: ${photoPaths[i]}');
          continue;
        }
        
        // Upload vers Cloudinary
        final folder = 'commandes/$commandeId';
        final url = await CloudinaryService.uploadImage(photoPaths[i], folder);
        uploadedUrls.add(url);
        
        print('[SUCCESS] Photo ${i + 1} uploadée: $url');
      }
      
      return uploadedUrls;
    } catch (e) {
      print('[ERROR] Erreur upload photos: $e');
      throw Exception('Erreur lors de l\'upload des photos');
    }
  }

  // M1 — Déléguer à GeolocationService (source unique de vérité)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return GeolocationService.calculateDistance(lat1, lon1, lat2, lon2);
  }

  // Envoyer un devis (artisan)
  Future<bool> envoyerDevis({
    required String commandeId,
    required double montantDevis,
    required String messageDevis,
    required double distanceKm,
  }) async {
    // ✅ IDEMPOTENCE: Vérifier si l'opération est déjà en cours
    final operationKey = 'devis_$commandeId';
    if (_isOperationInProgress(operationKey)) {
      print('[WARNING] Envoi de devis déjà en cours pour $commandeId');
      return false;
    }
    
    // Verrouiller l'opération
    _lockOperation(operationKey);
    
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
      
      // ✅ IDEMPOTENCE: Vérifier si un devis a déjà été envoyé
      if (commande.statut == 'devis_envoye' || commande.montantDevis != null) {
        print('[INFO] Devis déjà envoyé pour $commandeId');
        return true; // Retourner succès car déjà fait
      }
      
      // Calculer la commission (10%)
      final commission = montantDevis * 0.10;
      final montantArtisan = montantDevis - commission;
      
      // Mettre à jour la commande avec le devis
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'montantDevis': montantDevis,
        'messageDevis': messageDevis,
        'distanceKm': distanceKm,
        'dateDevis': Timestamp.now(),
        'statut': 'devis_envoye',
        'commission': commission,
        'montantArtisan': montantArtisan,
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour le client
      await FirestoreService.createNotification({
        'userId': commande.clientId,
        'type': 'devis_recu',
        'titre': 'Devis reçu !',
        'message': 'L\'artisan vous a envoyé un devis de ${montantDevis.toStringAsFixed(0)} FCFA',
        'data': {
          'commandeId': commandeId,
          'montantDevis': montantDevis,
          'distanceKm': distanceKm,
        },
      });

      print('[SUCCESS] Devis envoyé avec succès');
      return true;
    } catch (e) {
      print('[ERROR] Erreur envoi devis: $e');
      _errorMessage = 'Erreur lors de l\'envoi du devis';
      notifyListeners();
      return false;
    } finally {
      // ✅ IDEMPOTENCE: Toujours déverrouiller
      _unlockOperation(operationKey);
    }
  }

  // Accepter un devis (client)
  Future<bool> accepterDevis(String commandeId) async {
    // ✅ IDEMPOTENCE: Vérifier si l'opération est déjà en cours
    final operationKey = 'accepter_devis_$commandeId';
    if (_isOperationInProgress(operationKey)) {
      print('[WARNING] Acceptation de devis déjà en cours pour $commandeId');
      return false;
    }
    
    // Verrouiller l'opération
    _lockOperation(operationKey);
    
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
      
      if (commande.montantDevis == null) {
        _errorMessage = 'Aucun devis disponible';
        notifyListeners();
        return false;
      }
      
      // ✅ IDEMPOTENCE: Vérifier si déjà accepté
      if (commande.statut == 'devis_accepte' || commande.dateAcceptationDevis != null) {
        print('[INFO] Devis déjà accepté pour $commandeId');
        return true; // Retourner succès car déjà fait
      }
      
      // Mettre à jour la commande
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'montant': commande.montantDevis,
        'dateAcceptationDevis': Timestamp.now(),
        'statut': 'devis_accepte',
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour l'artisan
      await FirestoreService.createNotification({
        'userId': commande.artisanId,
        'type': 'devis_accepte',
        'titre': 'Devis accepté !',
        'message': 'Le client a accepté votre devis de ${commande.montantDevis!.toStringAsFixed(0)} FCFA',
        'data': {
          'commandeId': commandeId,
          'montant': commande.montantDevis,
        },
      });

      print('[SUCCESS] Devis accepté');
      return true;
    } catch (e) {
      print('[ERROR] Erreur acceptation devis: $e');
      _errorMessage = 'Erreur lors de l\'acceptation du devis';
      notifyListeners();
      return false;
    } finally {
      // ✅ IDEMPOTENCE: Toujours déverrouiller
      _unlockOperation(operationKey);
    }
  }

  // Refuser un devis (client)
  Future<bool> refuserDevis(String commandeId, String? raison) async {
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
      
      // Mettre à jour la commande
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': 'devis_refuse',
        'commentaireClient': raison,
        'updatedAt': Timestamp.now(),
      });

      // Créer une notification pour l'artisan
      await FirestoreService.createNotification({
        'userId': commande.artisanId,
        'type': 'devis_refuse',
        'titre': 'Devis refusé',
        'message': 'Le client a refusé votre devis${raison != null ? ": $raison" : ""}',
        'data': {
          'commandeId': commandeId,
        },
      });

      print('[SUCCESS] Devis refusé');
      return true;
    } catch (e) {
      print('[ERROR] Erreur refus devis: $e');
      _errorMessage = 'Erreur lors du refus du devis';
      notifyListeners();
      return false;
    }
  }

  // Marquer le paiement comme effectué (après paiement FedaPay - met en escrow)
  Future<bool> effectuerPaiement(String commandeId) async {
    // ✅ IDEMPOTENCE: Vérifier si l'opération est déjà en cours
    final operationKey = 'paiement_$commandeId';
    if (_isOperationInProgress(operationKey)) {
      print('[WARNING] Paiement déjà en cours pour $commandeId');
      return false;
    }
    
    // Verrouiller l'opération
    _lockOperation(operationKey);
    
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
      
      // ✅ IDEMPOTENCE: Vérifier si déjà en escrow ou débloqué
      if (commande.paiementStatut == 'bloque' ||
          commande.paiementStatut == 'debloque' ||
          commande.paiementStatut == 'paye') {
        print('[INFO] Paiement déjà effectué pour $commandeId (statut: ${commande.paiementStatut})');
        return true;
      }
      
      // Mettre le paiement en escrow (bloqué jusqu'à validation client)
      // NE PAS créditer l'artisan ici — seulement lors de validerPrestation()
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'paiementStatut': 'bloque', // Argent bloqué en escrow
        'statut': 'acceptee',       // Commande acceptée, travaux peuvent commencer
        'updatedAt': Timestamp.now(),
      });

      // Notifier l'artisan que le paiement est sécurisé
      await FirestoreService.createNotification({
        'userId': commande.artisanId,
        'type': 'paiement_recu',
        'titre': 'Paiement sécurisé !',
        'message': '${commande.montant.toStringAsFixed(0)} FCFA sont bloqués en escrow. Réalisez la prestation pour recevoir votre paiement.',
        'data': {
          'commandeId': commandeId,
          'montant': commande.montantArtisan,
        },
      });

      print('[SUCCESS] Paiement mis en escrow pour commande $commandeId');
      return true;
    } catch (e) {
      print('[ERROR] Erreur paiement: $e');
      _errorMessage = 'Erreur lors du paiement';
      notifyListeners();
      return false;
    } finally {
      // ✅ IDEMPOTENCE: Toujours déverrouiller
      _unlockOperation(operationKey);
    }
  }

  // Noter l'artisan (après validation)
  Future<bool> noterArtisan({
    required String commandeId,
    required String artisanId,
    required double note,
    required String commentaire,
  }) async {
    try {
      // Récupérer la commande pour le clientId
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

      // Enregistrer l'avis dans la collection dédiée
      await FirebaseService.firestore.collection('avis').add({
        'commandeId': commandeId,
        'artisanId': artisanId,
        'clientId': commande.clientId,
        'note': note,
        'commentaire': commentaire,
        'isVisible': true,
        'createdAt': Timestamp.now(),
      });

      // Mettre à jour la commande avec la note
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'noteArtisan': note,
        'commentaireClient': commentaire,
        'updatedAt': Timestamp.now(),
      });

      // Recalculer la note globale de l'artisan depuis tous ses avis
      final avisSnapshot = await FirebaseService.firestore
          .collection('avis')
          .where('artisanId', isEqualTo: artisanId)
          .where('isVisible', isEqualTo: true)
          .get();

      if (avisSnapshot.docs.isNotEmpty) {
        double totalNote = 0;
        for (var doc in avisSnapshot.docs) {
          totalNote += (doc.data()['note'] as num).toDouble();
        }
        final noteGlobale = totalNote / avisSnapshot.docs.length;

        final artisanQuery = await FirebaseService.firestore
            .collection('artisans')
            .where('userId', isEqualTo: artisanId)
            .limit(1)
            .get();

        if (artisanQuery.docs.isNotEmpty) {
          await artisanQuery.docs.first.reference.update({
            'noteGlobale': noteGlobale,
            'nombreAvis': avisSnapshot.docs.length,
            'updatedAt': Timestamp.now(),
          });
        }
      }

      // Notifier l'artisan
      await FirestoreService.createNotification({
        'userId': artisanId,
        'type': 'nouvelle_note',
        'titre': 'Nouvelle évaluation',
        'message': 'Vous avez reçu une note de $note/5',
        'data': {'commandeId': commandeId, 'note': note},
      });

      print('[SUCCESS] Note enregistrée: $note/5');
      return true;
    } catch (e) {
      print('[ERROR] Erreur notation: $e');
      _errorMessage = 'Erreur lors de la notation';
      notifyListeners();
      return false;
    }
  }
}