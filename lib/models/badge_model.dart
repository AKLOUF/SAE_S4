class BadgeModel {
  final String id;
  final String benevoleId;
  final String formationId;
  final String titre;
  final String description;
  final DateTime obtenuLe;

  BadgeModel({
    required this.id,
    required this.benevoleId,
    required this.formationId,
    required this.titre,
    required this.description,
    required this.obtenuLe,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map, String id) {
    return BadgeModel(
      id: id,
      benevoleId: map['benevoleId'] ?? '',
      formationId: map['formationId'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      obtenuLe: (map['obtenuLe'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'benevoleId': benevoleId,
      'formationId': formationId,
      'titre': titre,
      'description': description,
      'obtenuLe': obtenuLe,
    };
  }
}