import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final List<String> roles; // ["client", "artisan"] - peut avoir les deux
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String? photoUrl;
  final String ville;
  final String quartier;
  final GeoPoint position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool contratAccepte; // Si l'artisan a accepté le contrat
  final DateTime? dateAcceptationContrat;
  final bool paiementInscription; // Si l'artisan a payé les frais d'inscription
  final String? agentParrainId; // ID de l'agent qui a inscrit l'artisan
  final String? codeAgentParrain; // Code de parrainage de l'agent
  final DateTime? datePaiementInscription;
  final bool? isBanned; // Si l'utilisateur est banni
  final DateTime? bannedAt; // Date du bannissement
  final bool isAgent; // Si l'utilisateur est un agent validé
  final String? codePromoAgent; // Son propre code promo s'il est agent
  final String? agentStatus; // 'pending', 'approved', 'rejected'

  UserModel({
    required this.id,
    required this.roles,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    this.photoUrl,
    required this.ville,
    required this.quartier,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.contratAccepte = false,
    this.dateAcceptationContrat,
    this.paiementInscription = false,
    this.agentParrainId,
    this.codeAgentParrain,
    this.datePaiementInscription,
    this.isBanned,
    this.bannedAt,
    this.isAgent = false,
    this.codePromoAgent,
    this.agentStatus,
  });

  // Getter pour compatibilité avec l'ancien code (retourne le premier rôle)
  String get role => roles.isNotEmpty ? roles.first : 'client';
  
  // Vérifier si l'utilisateur a un rôle spécifique
  bool hasRole(String role) => roles.contains(role);
  
  // Vérifier si l'utilisateur est artisan
  bool get isArtisan => roles.contains('artisan');
  
  // Vérifier si l'utilisateur est client
  bool get isClient => roles.contains('client');

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Gérer l'ancien format (role: String) et le nouveau (roles: List)
    List<String> userRoles = [];
    if (data['roles'] != null && data['roles'] is List) {
      userRoles = List<String>.from(data['roles']);
    } else if (data['role'] != null) {
      // Migration de l'ancien format
      userRoles = [data['role']];
    }
    
    return UserModel(
      id: doc.id,
      roles: userRoles,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      ville: data['ville'] ?? '',
      quartier: data['quartier'] ?? '',
      position: data['position'] ?? const GeoPoint(0, 0),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      contratAccepte: data['contratAccepte'] ?? false,
      dateAcceptationContrat: data['dateAcceptationContrat'] != null 
          ? (data['dateAcceptationContrat'] as Timestamp).toDate() 
          : null,
      paiementInscription: data['paiementInscription'] ?? false,
      agentParrainId: data['agentParrainId'],
      codeAgentParrain: data['codeAgentParrain'],
      datePaiementInscription: data['datePaiementInscription'] != null 
          ? (data['datePaiementInscription'] as Timestamp).toDate() 
          : null,
      isBanned: data['isBanned'],
      bannedAt: data['bannedAt'] != null 
          ? (data['bannedAt'] as Timestamp).toDate() 
          : null,
      isAgent: data['isAgent'] ?? false,
      codePromoAgent: data['codePromoAgent'],
      agentStatus: data['agentStatus'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roles': roles,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'photoUrl': photoUrl,
      'ville': ville,
      'quartier': quartier,
      'position': position,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'contratAccepte': contratAccepte,
      'dateAcceptationContrat': dateAcceptationContrat != null 
          ? Timestamp.fromDate(dateAcceptationContrat!) 
          : null,
      'paiementInscription': paiementInscription,
      'agentParrainId': agentParrainId,
      'codeAgentParrain': codeAgentParrain,
      'datePaiementInscription': datePaiementInscription != null 
          ? Timestamp.fromDate(datePaiementInscription!) 
          : null,
      'isBanned': isBanned,
      'bannedAt': bannedAt != null 
          ? Timestamp.fromDate(bannedAt!) 
          : null,
      'isAgent': isAgent,
      'codePromoAgent': codePromoAgent,
      'agentStatus': agentStatus,
    };
  }

  String get fullName => '$prenom $nom';
  
  // Créer une copie avec un nouveau rôle ajouté
  UserModel copyWithAddedRole(String newRole) {
    if (roles.contains(newRole)) return this;
    
    return UserModel(
      id: id,
      roles: [...roles, newRole],
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      email: email,
      photoUrl: photoUrl,
      ville: ville,
      quartier: quartier,
      position: position,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive,
      contratAccepte: contratAccepte,
      dateAcceptationContrat: dateAcceptationContrat,
      paiementInscription: paiementInscription,
      agentParrainId: agentParrainId,
      codeAgentParrain: codeAgentParrain,
      datePaiementInscription: datePaiementInscription,
      isBanned: isBanned,
      bannedAt: bannedAt,
      isAgent: isAgent,
      codePromoAgent: codePromoAgent,
      agentStatus: agentStatus,
    );
  }
}

