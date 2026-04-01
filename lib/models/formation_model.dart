import 'package:cloud_firestore/cloud_firestore.dart';

class FormationModel {
  final String id;
  final String titre;
  final String description;
  final String formateurId;
  final DateTime dateCreation;
  final List<String> categories; // On garde List pour la compatibilité avec vos écrans
  final bool isActive;

  FormationModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.formateurId,
    required this.dateCreation,
    required this.categories,
    required this.isActive,
  });

  factory FormationModel.fromFirestore(Map<String, dynamic> data, String id) {
    // On récupère "thematique" et on le met dans une liste
    String promoType = data['thematique'] ?? 'inclusion';

    return FormationModel(
      id: id,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      formateurId: data['formateurId'] ?? data['createdBy'] ?? '',
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      categories: [promoType], // On transforme la String unique en Liste ici
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'formateurId': formateurId,
      'dateCreation': dateCreation,
      'thematique': categories.isNotEmpty ? categories.first : 'inclusion',
      'isActive': isActive,
    };
  }
}