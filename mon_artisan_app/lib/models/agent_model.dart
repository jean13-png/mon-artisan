import 'package:cloud_firestore/cloud_firestore.dart';

class AgentModel {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String codeParrainage; // Code unique de l'agent
  final String ville;
  final String quartier;
  final int nombreInscriptions; // Nombre d'artisans inscrits
  final double revenusTotal; // Total des commissions
  final double revenusDisponibles; // Commissions disponibles pour retrait
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgentModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.codeParrainage,
    required this.ville,
    required this.quartier,
    this.nombreInscriptions = 0,
    this.revenusTotal = 0.0,
    this.revenusDisponibles = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AgentModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      codeParrainage: data['codeParrainage'] ?? '',
      ville: data['ville'] ?? '',
      quartier: data['quartier'] ?? '',
      nombreInscriptions: data['nombreInscriptions'] ?? 0,
      revenusTotal: (data['revenusTotal'] ?? 0.0).toDouble(),
      revenusDisponibles: (data['revenusDisponibles'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'codeParrainage': codeParrainage,
      'ville': ville,
      'quartier': quartier,
      'nombreInscriptions': nombreInscriptions,
      'revenusTotal': revenusTotal,
      'revenusDisponibles': revenusDisponibles,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AgentModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? codeParrainage,
    String? ville,
    String? quartier,
    int? nombreInscriptions,
    double? revenusTotal,
    double? revenusDisponibles,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      codeParrainage: codeParrainage ?? this.codeParrainage,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      nombreInscriptions: nombreInscriptions ?? this.nombreInscriptions,
      revenusTotal: revenusTotal ?? this.revenusTotal,
      revenusDisponibles: revenusDisponibles ?? this.revenusDisponibles,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

