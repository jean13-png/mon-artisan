import 'package:cloud_firestore/cloud_firestore.dart';

class ArtisanModel {
  final String id;
  final String userId;
  final String metier;
  final String metierCategorie;
  final String description;
  final int experience;
  final Map<String, dynamic> tarifs;
  final bool disponibilite;
  final double rayonAction;
  final GeoPoint position;
  final String geohash;
  final String ville;
  final String quartier;
  final List<String> photos;
  final List<String> certifications;
  final double noteGlobale;
  final int nombreAvis;
  final int nombreCommandes;
  final double revenusTotal;
  final double revenusDisponibles;
  final bool isVerified;
  final String verificationStatus; // 'pending', 'approved', 'rejected'
  final bool isProfileComplete; // Si le profil est complet avec diplôme, CIP, photos
  final String? diplome; // URL du diplôme
  final String? cip; // Numéro CIP (Carte d'Identité Professionnelle)
  final List<String> atelierPhotos; // Photos de l'atelier/matériel
  final String? atelierAdresse; // Adresse de l'atelier
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Champs additionnels depuis UserModel (optionnels)
  final String? nom;
  final String? prenom;
  final String? photoUrl;
  final String? telephone;
  final String? email;

  ArtisanModel({
    required this.id,
    required this.userId,
    required this.metier,
    required this.metierCategorie,
    required this.description,
    required this.experience,
    required this.tarifs,
    this.disponibilite = true,
    this.rayonAction = 10.0,
    required this.position,
    required this.geohash,
    required this.ville,
    required this.quartier,
    this.photos = const [],
    this.certifications = const [],
    this.noteGlobale = 0.0,
    this.nombreAvis = 0,
    this.nombreCommandes = 0,
    this.revenusTotal = 0.0,
    this.revenusDisponibles = 0.0,
    this.isVerified = false,
    this.verificationStatus = 'pending',
    this.isProfileComplete = false,
    this.diplome,
    this.cip,
    this.atelierPhotos = const [],
    this.atelierAdresse,
    required this.createdAt,
    required this.updatedAt,
    this.nom,
    this.prenom,
    this.photoUrl,
    this.telephone,
    this.email,
  });

  factory ArtisanModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ArtisanModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      metier: data['metier'] ?? '',
      metierCategorie: data['metierCategorie'] ?? '',
      description: data['description'] ?? '',
      experience: data['experience'] ?? 0,
      tarifs: data['tarifs'] ?? {},
      disponibilite: data['disponibilite'] ?? true,
      rayonAction: (data['rayonAction'] ?? 10.0).toDouble(),
      position: data['position'] ?? const GeoPoint(0, 0),
      geohash: data['geohash'] ?? '',
      ville: data['ville'] ?? '',
      quartier: data['quartier'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      noteGlobale: (data['noteGlobale'] ?? 0.0).toDouble(),
      nombreAvis: data['nombreAvis'] ?? 0,
      nombreCommandes: data['nombreCommandes'] ?? 0,
      revenusTotal: (data['revenusTotal'] ?? 0.0).toDouble(),
      revenusDisponibles: (data['revenusDisponibles'] ?? 0.0).toDouble(),
      isVerified: data['isVerified'] ?? false,
      verificationStatus: data['verificationStatus'] ?? 'pending',
      isProfileComplete: data['isProfileComplete'] ?? false,
      diplome: data['diplome'],
      cip: data['cip'],
      atelierPhotos: List<String>.from(data['atelierPhotos'] ?? []),
      atelierAdresse: data['atelierAdresse'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      nom: data['nom'],
      prenom: data['prenom'],
      photoUrl: data['photoUrl'],
      telephone: data['telephone'],
      email: data['email'],
    );
  }
  
  String get fullName => '${prenom ?? ''} ${nom ?? ''}'.trim();

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'metier': metier,
      'metierCategorie': metierCategorie,
      'description': description,
      'experience': experience,
      'tarifs': tarifs,
      'disponibilite': disponibilite,
      'rayonAction': rayonAction,
      'position': position,
      'geohash': geohash,
      'ville': ville,
      'quartier': quartier,
      'photos': photos,
      'certifications': certifications,
      'noteGlobale': noteGlobale,
      'nombreAvis': nombreAvis,
      'nombreCommandes': nombreCommandes,
      'revenusTotal': revenusTotal,
      'revenusDisponibles': revenusDisponibles,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'isProfileComplete': isProfileComplete,
      'diplome': diplome,
      'cip': cip,
      'atelierPhotos': atelierPhotos,
      'atelierAdresse': atelierAdresse,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
