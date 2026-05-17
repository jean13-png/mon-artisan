import 'package:cloud_firestore/cloud_firestore.dart';

class MetierModel {
  final String id;
  final String nom;
  final String categorie;
  final String description;
  final String iconName;
  final int ordre;
  final bool isActive;

  MetierModel({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.description,
    required this.iconName,
    required this.ordre,
    this.isActive = true,
  });

  factory MetierModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MetierModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      categorie: data['categorie'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? '',
      ordre: data['ordre'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'categorie': categorie,
      'description': description,
      'iconName': iconName,
      'ordre': ordre,
      'isActive': isActive,
    };
  }
}
