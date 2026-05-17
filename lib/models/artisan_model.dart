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
  final String? cipPhoto; // URL de la photo de la carte CIP
  final List<String> atelierPhotos; // Photos de l'atelier/matériel
  final String? atelierAdresse; // Adresse de l'atelier
  
  // Disponibilité dynamique
  final String? commandeEnCours; // ID de la commande en cours
  final String? raisonIndisponibilite; // 'commande_en_cours', 'conge', 'autre'
  final DateTime? dateDebutIndisponibilite;
  final DateTime? dateFinIndisponibilite;
  final DateTime? locationUpdatedAt;
  
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
    this.cipPhoto,
    this.atelierPhotos = const [],
    this.atelierAdresse,
    this.commandeEnCours,
    this.raisonIndisponibilite,
    this.dateDebutIndisponibilite,
    this.dateFinIndisponibilite,
    required this.createdAt,
    required this.updatedAt,
    this.locationUpdatedAt,
    this.nom,
    this.prenom,
    this.photoUrl,
    this.telephone,
    this.email,
  });
  
  // Calculer si vraiment disponible
  bool get estRealementDisponible {
    return disponibilite && commandeEnCours == null;
  }

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
      cipPhoto: data['cipPhoto'],
      atelierPhotos: List<String>.from(data['atelierPhotos'] ?? []),
      atelierAdresse: data['atelierAdresse'],
      commandeEnCours: data['commandeEnCours'],
      raisonIndisponibilite: data['raisonIndisponibilite'],
      dateDebutIndisponibilite: data['dateDebutIndisponibilite'] != null 
          ? (data['dateDebutIndisponibilite'] as Timestamp).toDate() 
          : null,
      dateFinIndisponibilite: data['dateFinIndisponibilite'] != null 
          ? (data['dateFinIndisponibilite'] as Timestamp).toDate() 
          : null,
      locationUpdatedAt: data['locationUpdatedAt'] != null 
          ? (data['locationUpdatedAt'] as Timestamp).toDate() 
          : null,
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
  
  ArtisanModel copyWith({
    String? id,
    String? userId,
    String? metier,
    String? metierCategorie,
    String? description,
    int? experience,
    Map<String, dynamic>? tarifs,
    bool? disponibilite,
    double? rayonAction,
    GeoPoint? position,
    String? geohash,
    String? ville,
    String? quartier,
    List<String>? photos,
    List<String>? certifications,
    double? noteGlobale,
    int? nombreAvis,
    int? nombreCommandes,
    double? revenusTotal,
    double? revenusDisponibles,
    bool? isVerified,
    String? verificationStatus,
    bool? isProfileComplete,
    String? diplome,
    String? cip,
    String? cipPhoto,
    List<String>? atelierPhotos,
    String? atelierAdresse,
    String? commandeEnCours,
    String? raisonIndisponibilite,
    DateTime? dateDebutIndisponibilite,
    DateTime? dateFinIndisponibilite,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? locationUpdatedAt,
    String? nom,
    String? prenom,
    String? photoUrl,
    String? telephone,
    String? email,
  }) {
    return ArtisanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      metier: metier ?? this.metier,
      metierCategorie: metierCategorie ?? this.metierCategorie,
      description: description ?? this.description,
      experience: experience ?? this.experience,
      tarifs: tarifs ?? this.tarifs,
      disponibilite: disponibilite ?? this.disponibilite,
      rayonAction: rayonAction ?? this.rayonAction,
      position: position ?? this.position,
      geohash: geohash ?? this.geohash,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      photos: photos ?? this.photos,
      certifications: certifications ?? this.certifications,
      noteGlobale: noteGlobale ?? this.noteGlobale,
      nombreAvis: nombreAvis ?? this.nombreAvis,
      nombreCommandes: nombreCommandes ?? this.nombreCommandes,
      revenusTotal: revenusTotal ?? this.revenusTotal,
      revenusDisponibles: revenusDisponibles ?? this.revenusDisponibles,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      diplome: diplome ?? this.diplome,
      cip: cip ?? this.cip,
      cipPhoto: cipPhoto ?? this.cipPhoto,
      atelierPhotos: atelierPhotos ?? this.atelierPhotos,
      atelierAdresse: atelierAdresse ?? this.atelierAdresse,
      commandeEnCours: commandeEnCours ?? this.commandeEnCours,
      raisonIndisponibilite: raisonIndisponibilite ?? this.raisonIndisponibilite,
      dateDebutIndisponibilite: dateDebutIndisponibilite ?? this.dateDebutIndisponibilite,
      dateFinIndisponibilite: dateFinIndisponibilite ?? this.dateFinIndisponibilite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      photoUrl: photoUrl ?? this.photoUrl,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
    );
  }

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
      'cipPhoto': cipPhoto,
      'atelierPhotos': atelierPhotos,
      'atelierAdresse': atelierAdresse,
      'commandeEnCours': commandeEnCours,
      'raisonIndisponibilite': raisonIndisponibilite,
      'dateDebutIndisponibilite': dateDebutIndisponibilite != null
          ? Timestamp.fromDate(dateDebutIndisponibilite!)
          : null,
      'dateFinIndisponibilite': dateFinIndisponibilite != null
          ? Timestamp.fromDate(dateFinIndisponibilite!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'locationUpdatedAt': locationUpdatedAt != null ? Timestamp.fromDate(locationUpdatedAt!) : null,
      // Mi7 — Inclure les champs dénormalisés depuis UserModel
      'nom': nom,
      'prenom': prenom,
      'photoUrl': photoUrl,
      'telephone': telephone,
      'email': email,
    };
  }
}
