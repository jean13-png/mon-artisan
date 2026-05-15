import 'package:cloud_firestore/cloud_firestore.dart';

class CommandeModel {
  final String id;
  final String clientId;
  final String artisanId;
  final String metier;
  final String typeCommande; // 'panne_connue' ou 'diagnostic_requis'
  final String titre; // Titre de la commande
  final String description;
  final String adresse;
  final GeoPoint position;
  final String ville;
  final String quartier;
  final DateTime dateIntervention;
  final String heureIntervention;
  final String statut;
  final double montant;
  final double? montantDevis; // Montant proposé par l'artisan dans le devis
  final String? messageDevis; // Message de l'artisan avec le devis
  final double? fraisDeplacement; // Frais de déplacement pour diagnostic (500-1000 FCFA)
  final bool? fraisDeplacementPayes; // Si les frais de déplacement ont été payés
  final String? fedapayTransactionIdDeplacement; // ID transaction FedaPay pour frais déplacement
  final double? distanceKm; // Distance calculée entre artisan et client
  final DateTime? dateDevis; // Date d'envoi du devis
  final DateTime? dateAcceptationDevis; // Date d'acceptation du devis par le client
  final double commission;
  final double montantArtisan;
  final String paiementStatut; // 'en_attente', 'bloque', 'debloque', 'rembourse'
  final String? fedapayTransactionId;
  final DateTime? dateValidationClient; // Date de validation de la prestation par le client
  final DateTime? dateDeblocagePaiement; // Date de déblocage du paiement
  final List<String> photos;
  final double? noteClient;
  final double? noteArtisan;
  final String? commentaireClient;
  final String? commentaireArtisan;
  
  // Partage de localisation
  final GeoPoint? clientPosition; // Position GPS exacte du client
  final String? clientAdresseExacte; // Adresse complète récupérée via geocoding
  final bool clientPositionPartagee; // Si le client a partagé sa position
  final DateTime? datePartagePosition; // Date du partage de position

  // Flux diagnostic
  final bool diagnosticValideArtisan; // Artisan a confirmé être sur place
  final String? descriptionProbleme; // Description du problème après diagnostic
  final String? justificationMontant; // Justification optionnelle du montant
  final double? montantDiagnostic; // Frais de déplacement calculés dynamiquement
  final String? fedapayTransactionIdDiagnostic; // Transaction du paiement diagnostic
  final DateTime? dateDiagnosticValide; // Date où artisan a validé le diagnostic
  
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  CommandeModel({
    required this.id,
    required this.clientId,
    required this.artisanId,
    required this.metier,
    this.typeCommande = 'panne_connue', // Par défaut
    this.titre = '',
    required this.description,
    required this.adresse,
    required this.position,
    required this.ville,
    required this.quartier,
    required this.dateIntervention,
    required this.heureIntervention,
    this.statut = 'en_attente',
    required this.montant,
    this.montantDevis,
    this.messageDevis,
    this.fraisDeplacement,
    this.fraisDeplacementPayes,
    this.fedapayTransactionIdDeplacement,
    this.distanceKm,
    this.dateDevis,
    this.dateAcceptationDevis,
    required this.commission,
    required this.montantArtisan,
    this.paiementStatut = 'en_attente',
    this.fedapayTransactionId,
    this.dateValidationClient,
    this.dateDeblocagePaiement,
    this.photos = const [],
    this.noteClient,
    this.noteArtisan,
    this.commentaireClient,
    this.commentaireArtisan,
    this.clientPosition,
    this.clientAdresseExacte,
    this.clientPositionPartagee = false,
    this.datePartagePosition,
    this.diagnosticValideArtisan = false,
    this.descriptionProbleme,
    this.justificationMontant,
    this.montantDiagnostic,
    this.fedapayTransactionIdDiagnostic,
    this.dateDiagnosticValide,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory CommandeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommandeModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      artisanId: data['artisanId'] ?? '',
      metier: data['metier'] ?? '',
      typeCommande: data['typeCommande'] ?? 'panne_connue',
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      adresse: data['adresse'] ?? '',
      position: data['position'] ?? const GeoPoint(0, 0),
      ville: data['ville'] ?? '',
      quartier: data['quartier'] ?? '',
      dateIntervention: (data['dateIntervention'] as Timestamp).toDate(),
      heureIntervention: data['heureIntervention'] ?? '',
      statut: data['statut'] ?? 'en_attente',
      montant: (data['montant'] ?? 0.0).toDouble(),
      montantDevis: data['montantDevis']?.toDouble(),
      messageDevis: data['messageDevis'],
      fraisDeplacement: data['fraisDeplacement']?.toDouble(),
      fraisDeplacementPayes: data['fraisDeplacementPayes'],
      fedapayTransactionIdDeplacement: data['fedapayTransactionIdDeplacement'],
      distanceKm: data['distanceKm']?.toDouble(),
      dateDevis: data['dateDevis'] != null ? (data['dateDevis'] as Timestamp).toDate() : null,
      dateAcceptationDevis: data['dateAcceptationDevis'] != null ? (data['dateAcceptationDevis'] as Timestamp).toDate() : null,
      commission: (data['commission'] ?? 0.0).toDouble(),
      montantArtisan: (data['montantArtisan'] ?? 0.0).toDouble(),
      paiementStatut: data['paiementStatut'] ?? 'en_attente',
      fedapayTransactionId: data['fedapayTransactionId'],
      dateValidationClient: data['dateValidationClient'] != null 
          ? (data['dateValidationClient'] as Timestamp).toDate() 
          : null,
      dateDeblocagePaiement: data['dateDeblocagePaiement'] != null 
          ? (data['dateDeblocagePaiement'] as Timestamp).toDate() 
          : null,
      photos: List<String>.from(data['photos'] ?? []),
      noteClient: data['noteClient']?.toDouble(),
      noteArtisan: data['noteArtisan']?.toDouble(),
      commentaireClient: data['commentaireClient'],
      commentaireArtisan: data['commentaireArtisan'],
      clientPosition: data['clientPosition'],
      clientAdresseExacte: data['clientAdresseExacte'],
      clientPositionPartagee: data['clientPositionPartagee'] ?? false,
      datePartagePosition: data['datePartagePosition'] != null 
          ? (data['datePartagePosition'] as Timestamp).toDate() 
          : null,
      diagnosticValideArtisan: data['diagnosticValideArtisan'] ?? false,
      descriptionProbleme: data['descriptionProbleme'],
      justificationMontant: data['justificationMontant'],
      montantDiagnostic: data['montantDiagnostic']?.toDouble(),
      fedapayTransactionIdDiagnostic: data['fedapayTransactionIdDiagnostic'],
      dateDiagnosticValide: data['dateDiagnosticValide'] != null
          ? (data['dateDiagnosticValide'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null ? (data['acceptedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'artisanId': artisanId,
      'metier': metier,
      'typeCommande': typeCommande,
      'titre': titre,
      'description': description,
      'adresse': adresse,
      'position': position,
      'ville': ville,
      'quartier': quartier,
      'dateIntervention': Timestamp.fromDate(dateIntervention),
      'heureIntervention': heureIntervention,
      'statut': statut,
      'montant': montant,
      'montantDevis': montantDevis,
      'messageDevis': messageDevis,
      'fraisDeplacement': fraisDeplacement,
      'fraisDeplacementPayes': fraisDeplacementPayes,
      'fedapayTransactionIdDeplacement': fedapayTransactionIdDeplacement,
      'distanceKm': distanceKm,
      'dateDevis': dateDevis != null ? Timestamp.fromDate(dateDevis!) : null,
      'dateAcceptationDevis': dateAcceptationDevis != null ? Timestamp.fromDate(dateAcceptationDevis!) : null,
      'commission': commission,
      'montantArtisan': montantArtisan,
      'paiementStatut': paiementStatut,
      'fedapayTransactionId': fedapayTransactionId,
      'dateValidationClient': dateValidationClient != null 
          ? Timestamp.fromDate(dateValidationClient!) 
          : null,
      'dateDeblocagePaiement': dateDeblocagePaiement != null 
          ? Timestamp.fromDate(dateDeblocagePaiement!) 
          : null,
      'photos': photos,
      'noteClient': noteClient,
      'noteArtisan': noteArtisan,
      'commentaireClient': commentaireClient,
      'commentaireArtisan': commentaireArtisan,
      'clientPosition': clientPosition,
      'clientAdresseExacte': clientAdresseExacte,
      'clientPositionPartagee': clientPositionPartagee,
      'datePartagePosition': datePartagePosition != null 
          ? Timestamp.fromDate(datePartagePosition!) 
          : null,
      'diagnosticValideArtisan': diagnosticValideArtisan,
      'descriptionProbleme': descriptionProbleme,
      'justificationMontant': justificationMontant,
      'montantDiagnostic': montantDiagnostic,
      'fedapayTransactionIdDiagnostic': fedapayTransactionIdDiagnostic,
      'dateDiagnosticValide': dateDiagnosticValide != null
          ? Timestamp.fromDate(dateDiagnosticValide!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CommandeModel copyWith({
    String? id,
    String? clientId,
    String? artisanId,
    String? metier,
    String? typeCommande,
    String? titre,
    String? description,
    String? adresse,
    GeoPoint? position,
    String? ville,
    String? quartier,
    DateTime? dateIntervention,
    String? heureIntervention,
    String? statut,
    double? montant,
    double? montantDevis,
    String? messageDevis,
    double? fraisDeplacement,
    bool? fraisDeplacementPayes,
    String? fedapayTransactionIdDeplacement,
    double? distanceKm,
    DateTime? dateDevis,
    DateTime? dateAcceptationDevis,
    double? commission,
    double? montantArtisan,
    String? paiementStatut,
    String? fedapayTransactionId,
    DateTime? dateValidationClient,
    DateTime? dateDeblocagePaiement,
    List<String>? photos,
    double? noteClient,
    double? noteArtisan,
    String? commentaireClient,
    String? commentaireArtisan,
    GeoPoint? clientPosition,
    String? clientAdresseExacte,
    bool? clientPositionPartagee,
    DateTime? datePartagePosition,
    bool? diagnosticValideArtisan,
    String? descriptionProbleme,
    String? justificationMontant,
    double? montantDiagnostic,
    String? fedapayTransactionIdDiagnostic,
    DateTime? dateDiagnosticValide,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return CommandeModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      artisanId: artisanId ?? this.artisanId,
      metier: metier ?? this.metier,
      typeCommande: typeCommande ?? this.typeCommande,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      adresse: adresse ?? this.adresse,
      position: position ?? this.position,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      dateIntervention: dateIntervention ?? this.dateIntervention,
      heureIntervention: heureIntervention ?? this.heureIntervention,
      statut: statut ?? this.statut,
      montant: montant ?? this.montant,
      montantDevis: montantDevis ?? this.montantDevis,
      messageDevis: messageDevis ?? this.messageDevis,
      fraisDeplacement: fraisDeplacement ?? this.fraisDeplacement,
      fraisDeplacementPayes: fraisDeplacementPayes ?? this.fraisDeplacementPayes,
      fedapayTransactionIdDeplacement: fedapayTransactionIdDeplacement ?? this.fedapayTransactionIdDeplacement,
      distanceKm: distanceKm ?? this.distanceKm,
      dateDevis: dateDevis ?? this.dateDevis,
      dateAcceptationDevis: dateAcceptationDevis ?? this.dateAcceptationDevis,
      commission: commission ?? this.commission,
      montantArtisan: montantArtisan ?? this.montantArtisan,
      paiementStatut: paiementStatut ?? this.paiementStatut,
      fedapayTransactionId: fedapayTransactionId ?? this.fedapayTransactionId,
      dateValidationClient: dateValidationClient ?? this.dateValidationClient,
      dateDeblocagePaiement: dateDeblocagePaiement ?? this.dateDeblocagePaiement,
      photos: photos ?? this.photos,
      noteClient: noteClient ?? this.noteClient,
      noteArtisan: noteArtisan ?? this.noteArtisan,
      commentaireClient: commentaireClient ?? this.commentaireClient,
      commentaireArtisan: commentaireArtisan ?? this.commentaireArtisan,
      clientPosition: clientPosition ?? this.clientPosition,
      clientAdresseExacte: clientAdresseExacte ?? this.clientAdresseExacte,
      clientPositionPartagee: clientPositionPartagee ?? this.clientPositionPartagee,
      datePartagePosition: datePartagePosition ?? this.datePartagePosition,
      diagnosticValideArtisan: diagnosticValideArtisan ?? this.diagnosticValideArtisan,
      descriptionProbleme: descriptionProbleme ?? this.descriptionProbleme,
      justificationMontant: justificationMontant ?? this.justificationMontant,
      montantDiagnostic: montantDiagnostic ?? this.montantDiagnostic,
      fedapayTransactionIdDiagnostic: fedapayTransactionIdDiagnostic ?? this.fedapayTransactionIdDiagnostic,
      dateDiagnosticValide: dateDiagnosticValide ?? this.dateDiagnosticValide,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
