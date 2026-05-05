import 'package:cloud_firestore/cloud_firestore.dart';

class CommandeModel {
  final String id;
  final String clientId;
  final String artisanId;
  final String metier;
  final String description;
  final String adresse;
  final GeoPoint position;
  final String ville;
  final String quartier;
  final DateTime dateIntervention;
  final String heureIntervention;
  final String statut;
  final double montant;
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
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  CommandeModel({
    required this.id,
    required this.clientId,
    required this.artisanId,
    required this.metier,
    required this.description,
    required this.adresse,
    required this.position,
    required this.ville,
    required this.quartier,
    required this.dateIntervention,
    required this.heureIntervention,
    this.statut = 'en_attente',
    required this.montant,
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
      description: data['description'] ?? '',
      adresse: data['adresse'] ?? '',
      position: data['position'] ?? const GeoPoint(0, 0),
      ville: data['ville'] ?? '',
      quartier: data['quartier'] ?? '',
      dateIntervention: (data['dateIntervention'] as Timestamp).toDate(),
      heureIntervention: data['heureIntervention'] ?? '',
      statut: data['statut'] ?? 'en_attente',
      montant: (data['montant'] ?? 0.0).toDouble(),
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
      'description': description,
      'adresse': adresse,
      'position': position,
      'ville': ville,
      'quartier': quartier,
      'dateIntervention': Timestamp.fromDate(dateIntervention),
      'heureIntervention': heureIntervention,
      'statut': statut,
      'montant': montant,
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
    String? description,
    String? adresse,
    GeoPoint? position,
    String? ville,
    String? quartier,
    DateTime? dateIntervention,
    String? heureIntervention,
    String? statut,
    double? montant,
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
      description: description ?? this.description,
      adresse: adresse ?? this.adresse,
      position: position ?? this.position,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      dateIntervention: dateIntervention ?? this.dateIntervention,
      heureIntervention: heureIntervention ?? this.heureIntervention,
      statut: statut ?? this.statut,
      montant: montant ?? this.montant,
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
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
