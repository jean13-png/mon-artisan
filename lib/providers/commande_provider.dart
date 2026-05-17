import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/commande_model.dart';
import '../core/constants/app_constants.dart';
import '../core/services/firebase_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/cloudinary_service.dart';
import '../core/services/geolocation_service.dart';

class CommandeProvider extends ChangeNotifier {
  List<CommandeModel> _commandes = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final int _limit = 20;

  // Système d'idempotence - Verrouillage des opérations
  final Set<String> _operationsEnCours = {};

  List<CommandeModel> get commandes => _commandes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  
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
      // Si c'est un diagnostic, la base est les frais de déplacement
      final baseCalcul = typeCommande == 'diagnostic_requis' ? (fraisDeplacement ?? 0.0) : montant;
      final commission = baseCalcul * AppConstants.commissionRate;
      final montantArtisan = baseCalcul - commission;

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
        fraisDeplacement: fraisDeplacement, // calculé dynamiquement par l'appelant
        montantDiagnostic: fraisDeplacement, // même valeur, stockée séparément
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
  


  // Réinitialiser la pagination
  void resetPagination() {
    _commandes = [];
    _lastDocument = null;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }

  // Récupérer les commandes d'un client (paginé)
  Future<void> loadClientCommandes(String clientId) async {
    resetPagination();
    await _fetchCommandes(
      FirebaseService.firestore
          .collection('commandes')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true),
    );
  }

  // Charger plus de commandes pour le client
  Future<void> loadMoreClientCommandes(String clientId) async {
    if (_isLoading || !_hasMore) return;
    await _fetchCommandes(
      FirebaseService.firestore
          .collection('commandes')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true),
      isLoadMore: true,
    );
  }

  // Récupérer les commandes d'un artisan (paginé)
  Future<void> loadArtisanCommandes(String artisanId) async {
    resetPagination();
    await _fetchCommandes(
      FirebaseService.firestore
          .collection('commandes')
          .where('artisanId', isEqualTo: artisanId)
          .orderBy('createdAt', descending: true),
    );
  }

  // Charger plus de commandes pour l'artisan
  Future<void> loadMoreArtisanCommandes(String artisanId) async {
    if (_isLoading || !_hasMore) return;
    await _fetchCommandes(
      FirebaseService.firestore
          .collection('commandes')
          .where('artisanId', isEqualTo: artisanId)
          .orderBy('createdAt', descending: true),
      isLoadMore: true,
    );
  }

  // Méthode générique de récupération paginée
  Future<void> _fetchCommandes(Query query, {bool isLoadMore = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query paginatedQuery = query.limit(_limit);
      
      if (isLoadMore && _lastDocument != null) {
        paginatedQuery = paginatedQuery.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await paginatedQuery.get();

      if (querySnapshot.docs.length < _limit) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        
        final newCommandes = querySnapshot.docs
            .map((doc) => CommandeModel.fromFirestore(doc))
            .toList();

        if (isLoadMore) {
          _commandes.addAll(newCommandes);
        } else {
          _commandes = newCommandes;
        }
      } else if (!isLoadMore) {
        _commandes = [];
        _hasMore = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[ERROR] Erreur _fetchCommandes: $e');
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des commandes. Vérifiez vos index Firestore.';
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
      
      final newStatut = commande.typeCommande == 'diagnostic_requis' 
          ? 'diagnostic_acceptee' 
          : 'acceptee';
      
      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': newStatut,
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
  Future<bool> refuserCommande(String commandeId, [String? raison]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Récupérer la commande pour libérer l'artisan
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .get();

      if (!commandeDoc.exists) {
        _errorMessage = 'Commande introuvable';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final commande = CommandeModel.fromFirestore(commandeDoc);

      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'statut': 'refusee',
        'motifRefus': raison,
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

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
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

  // ─── DIAGNOSTIC : Artisan confirme être sur place ─────────────────────────
  Future<bool> validerDiagnosticArtisan(String commandeId) async {
    final operationKey = 'valider_diag_$commandeId';
    if (_isOperationInProgress(operationKey)) return false;
    _lockOperation(operationKey);

    try {
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes').doc(commandeId).get();
      if (!commandeDoc.exists) { _errorMessage = 'Commande introuvable'; notifyListeners(); return false; }

      final commande = CommandeModel.fromFirestore(commandeDoc);

      // Idempotence
      if (commande.diagnosticValideArtisan) return true;

      await FirebaseService.firestore.collection('commandes').doc(commandeId).update({
        'diagnosticValideArtisan': true,
        'dateDiagnosticValide': Timestamp.now(),
        'statut': 'diagnostic_valide',
        'updatedAt': Timestamp.now(),
      });

      // ✅ Si les frais de déplacement ont été payés (bloqués), on les crédite à l'artisan
      if (commande.fraisDeplacementPayes == true && commande.montantDiagnostic != null) {
        // Pour les frais de déplacement, on crédite le montant net à l'artisan
        await FirestoreService.crediterArtisan(commande.artisanId, commande.montantDiagnostic!);
        print('[SUCCESS] Frais de diagnostic (${commande.montantDiagnostic} FCFA) crédités à l\'artisan');
      }

      // Notifier le client
      await FirestoreService.createNotification({
        'userId': commande.clientId,
        'type': 'diagnostic_valide',
        'titre': 'Diagnostic effectué',
        'message': 'L\'artisan est arrivé et a effectué le diagnostic. Un devis vous sera envoyé prochainement.',
        'data': {'commandeId': commandeId},
      });

      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la validation du diagnostic: $e';
      notifyListeners();
      return false;
    } finally {
      _unlockOperation(operationKey);
    }
  }

  // ─── DIAGNOSTIC : Artisan soumet le devis final après intervention ──────────
  Future<bool> soumettreDevisPostDiagnostic({
    required String commandeId,
    required double montantDevis,
    required String descriptionProbleme,
    String? justificationMontant,
  }) async {
    final operationKey = 'devis_post_diag_$commandeId';
    if (_isOperationInProgress(operationKey)) return false;
    _lockOperation(operationKey);

    try {
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes').doc(commandeId).get();
      if (!commandeDoc.exists) { _errorMessage = 'Commande introuvable'; notifyListeners(); return false; }

      final commande = CommandeModel.fromFirestore(commandeDoc);

      final commissionDevis = montantDevis * AppConstants.commissionRate;
      final montantArtisanDevis = montantDevis - commissionDevis;

      // Calculer le nouveau total (Diagnostic déjà payé + Devis final)
      final nouveauMontantTotal = (commande.montantDiagnostic ?? 0.0) + montantDevis;
      final nouvelleCommissionTotale = commande.commission + commissionDevis;
      final nouveauMontantArtisanTotal = commande.montantArtisan + montantArtisanDevis;

      await FirebaseService.firestore.collection('commandes').doc(commandeId).update({
        'montantDevis': montantDevis,
        'descriptionProbleme': descriptionProbleme,
        'justificationMontant': justificationMontant,
        'statut': 'devis_post_diagnostic_envoye',
        'montant': nouveauMontantTotal, // Le montant total de la commande inclut maintenant le devis
        'commission': nouvelleCommissionTotale,
        'montantArtisan': nouveauMontantArtisanTotal,
        'dateDevis': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Notifier le client
      await FirestoreService.createNotification({
        'userId': commande.clientId,
        'type': 'devis_post_diagnostic',
        'titre': 'Devis reçu !',
        'message': 'L\'artisan vous a envoyé un devis de ${montantDevis.toStringAsFixed(0)} FCFA après diagnostic.',
        'data': {
          'commandeId': commandeId,
          'montantDevis': montantDevis,
        },
      });

      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'envoi du devis post-diagnostic: $e';
      notifyListeners();
      return false;
    } finally {
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
      final nouveauStatut = commande.statut == 'devis_post_diagnostic_envoye' 
          ? 'devis_post_diagnostic_accepte' 
          : 'devis_accepte';

      // Le montant est déjà mis à jour de manière cumulative dans soumettreDevisPostDiagnostic
      // On ne le met à jour ici que si c'est une commande classique (non diagnostic)
      final mapUpdate = {
        'dateAcceptationDevis': Timestamp.now(),
        'statut': nouveauStatut,
        'updatedAt': Timestamp.now(),
      };
      
      if (commande.typeCommande != 'diagnostic_requis') {
        mapUpdate['montant'] = commande.montantDevis!;
      }

      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update(mapUpdate);

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

  // Annuler complètement la commande
  Future<bool> annulerCommande(String commandeId) async {
    final operationKey = 'annuler_$commandeId';
    if (_isOperationInProgress(operationKey)) return false;
    _lockOperation(operationKey);
    
    try {
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
        'statut': 'annulee',
        'updatedAt': Timestamp.now(),
      });
      
      await FirestoreService.createNotification({
        'userId': commande.artisanId,
        'type': 'commande_annulee',
        'titre': 'Commande annulée',
        'message': 'Le client a annulé la commande',
        'data': {
          'commandeId': commandeId,
        },
      });
      
      return true;
    } catch (e) {
      print('[ERROR] Erreur annulation: $e');
      _errorMessage = 'Erreur lors de l\'annulation de la commande';
      notifyListeners();
      return false;
    } finally {
      _unlockOperation(operationKey);
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
      
      // ✅ IDEMPOTENCE & FLUX: Vérifier si déjà payé pour ce flux
      if (commande.statut == 'diagnostic_demande' && commande.fraisDeplacementPayes == true) {
        print('[INFO] Frais de diagnostic déjà payés pour $commandeId');
        return true;
      }
      
      if (commande.statut == 'devis_post_diagnostic_accepte' && commande.paiementStatut == 'bloque' && (commande.fedapayTransactionId?.isNotEmpty ?? false)) {
         print('[INFO] Paiement final déjà effectué pour $commandeId');
         return true;
      }

      // Mettre le paiement en escrow (bloqué jusqu'à validation client)
      // Déterminer le nouveau statut en fonction du flux
      String nouveauStatut = 'acceptee';
      String messageNotif = '${commande.montant.toStringAsFixed(0)} FCFA sont bloqués en escrow. Réalisez la prestation pour recevoir votre paiement.';

      if (commande.statut == 'diagnostic_demande' || commande.statut == 'diagnostic_acceptee') {
        nouveauStatut = 'diagnostic_paye';
        messageNotif = 'Le client a payé les frais de diagnostic (${commande.fraisDeplacement?.toStringAsFixed(0)} FCFA). Vous pouvez vous déplacer.';
      } else if (commande.statut == 'devis_post_diagnostic_envoye' || commande.statut == 'devis_post_diagnostic_accepte') {
        nouveauStatut = 'en_cours';
        messageNotif = 'Le paiement du devis final a été effectué. Vous pouvez terminer les travaux.';
      }

      await FirebaseService.firestore
          .collection('commandes')
          .doc(commandeId)
          .update({
        'paiementStatut': 'bloque', // Argent bloqué en escrow
        'statut': nouveauStatut,
        'fraisDeplacementPayes': (commande.statut == 'diagnostic_demande') ? true : commande.fraisDeplacementPayes,
        'updatedAt': Timestamp.now(),
      });

      // Notifier l'artisan que le paiement est sécurisé
      await FirestoreService.createNotification({
        'userId': commande.artisanId,
        'type': 'paiement_recu',
        'titre': 'Paiement sécurisé !',
        'message': messageNotif,
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

  // Valider la prestation (Client confirme que le travail est fait - libère l'argent)
  Future<bool> validerPrestation(String commandeId) async {
    final operationKey = 'valider_prest_$commandeId';
    if (_isOperationInProgress(operationKey)) return false;
    _lockOperation(operationKey);

    try {
      final commandeDoc = await FirebaseService.firestore
          .collection('commandes').doc(commandeId).get();
      if (!commandeDoc.exists) { _errorMessage = 'Commande introuvable'; notifyListeners(); return false; }

      final commande = CommandeModel.fromFirestore(commandeDoc);

      // Vérifier si déjà validé
      if (commande.statut == 'validee') return true;

      // Mettre à jour la commande
      await FirebaseService.firestore.collection('commandes').doc(commandeId).update({
        'statut': 'validee',
        'paiementStatut': 'debloque',
        'dateValidationClient': Timestamp.now(),
        'dateDeblocagePaiement': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // ✅ Créditer l'artisan pour le montant final
      await FirestoreService.crediterArtisan(commande.artisanId, commande.montantArtisan);

      // ✅ Libérer l'artisan (le rendre disponible)
      await FirestoreService.setArtisanAvailable(commande.artisanId);

      // Notifier l'artisan
      await FirestoreService.createNotification({
        'userId': commande.artisanId,
        'type': 'prestation_validee',
        'titre': 'Paiement débloqué !',
        'message': 'Le client a validé la prestation. ${commande.montantArtisan.toStringAsFixed(0)} FCFA ont été ajoutés à votre solde.',
        'data': {'commandeId': commandeId, 'montant': commande.montantArtisan},
      });

      print('[SUCCESS] Prestation validée par le client. Argent débloqué.');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la validation: $e';
      notifyListeners();
      return false;
    } finally {
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
      // On filtre en mémoire pour éviter d'avoir besoin d'un index composite Firestore
      final avisSnapshot = await FirebaseService.firestore
          .collection('avis')
          .where('artisanId', isEqualTo: artisanId)
          .get();

      if (avisSnapshot.docs.isNotEmpty) {
        final avisVisibles = avisSnapshot.docs.where((doc) => doc.data()['isVisible'] == true).toList();
        
        if (avisVisibles.isNotEmpty) {
          double totalNote = 0;
          for (var doc in avisVisibles) {
            totalNote += (doc.data()['note'] as num).toDouble();
          }
          final noteGlobale = totalNote / avisVisibles.length;

          final artisanQuery = await FirebaseService.firestore
              .collection('artisans')
              .where('userId', isEqualTo: artisanId)
              .limit(1)
              .get();

          if (artisanQuery.docs.isNotEmpty) {
            await artisanQuery.docs.first.reference.update({
              'noteGlobale': noteGlobale,
              'nombreAvis': avisVisibles.length,
              'updatedAt': Timestamp.now(),
            });
            print('[SUCCESS] Note globale de l\'artisan mise à jour: ${noteGlobale.toStringAsFixed(1)}');
          }
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