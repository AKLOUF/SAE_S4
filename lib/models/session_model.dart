import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String formationId;
  final String formationTitre;
  final String formateurId;
  final String formateurNom;
  final DateTime date;
  final String heureDebut; // ex: "09:00"
  final String heureFin;   // ex: "11:00"
  final List<String> participantsIds;
  final String statut; // 'planifiee' | 'en_cours' | 'terminee'
  final String titre;
  final int maxParticipants;

  SessionModel({
    required this.id,
    required this.formationId,
    this.formationTitre = '',
    required this.formateurId,
    this.formateurNom = '',
    required this.date,
    this.heureDebut = '',
    this.heureFin = '',
    required this.participantsIds,
    required this.statut,
    this.titre = '',
    this.maxParticipants = 20,
  });

  bool get estComplet => participantsIds.length >= maxParticipants;
  int get placesRestantes => maxParticipants - participantsIds.length;

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: id,
      formationId: map['formationId'] ?? '',
      formationTitre: map['formationTitre'] ?? map['formation'] ?? '',
      formateurId: map['formateurId'] ?? '',
      formateurNom: map['formateurNom'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      heureDebut: map['heureDebut'] ?? '',
      heureFin: map['heureFin'] ?? '',
      participantsIds: List<String>.from(map['participantsIds'] ?? []),
      statut: map['statut'] ?? 'planifiee',
      titre: map['titre'] ?? '',
      maxParticipants: map['maxParticipants'] ?? 20,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'formationId': formationId,
      'formationTitre': formationTitre,
      'formateurId': formateurId,
      'formateurNom': formateurNom,
      'date': Timestamp.fromDate(date),
      'heureDebut': heureDebut,
      'heureFin': heureFin,
      'participantsIds': participantsIds,
      'statut': statut,
      'titre': titre,
      'maxParticipants': maxParticipants,
    };
  }

  SessionModel copyWith({
    String? statut,
    List<String>? participantsIds,
    String? titre,
    String? formateurId,
    String? formateurNom,
    int? maxParticipants,
    DateTime? date,
    String? heureDebut,
    String? heureFin,
  }) {
    return SessionModel(
      id: id,
      formationId: formationId,
      formationTitre: formationTitre,
      formateurId: formateurId ?? this.formateurId,
      formateurNom: formateurNom ?? this.formateurNom,
      date: date ?? this.date,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      participantsIds: participantsIds ?? this.participantsIds,
      statut: statut ?? this.statut,
      titre: titre ?? this.titre,
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }
}