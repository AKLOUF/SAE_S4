class QuizResultModel {
  final String id;
  final String benevoleId;
  final String formationId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final bool badgeObtenu;

  QuizResultModel({
    required this.id,
    required this.benevoleId,
    required this.formationId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.badgeObtenu,
  });

  double get pourcentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  factory QuizResultModel.fromMap(Map<String, dynamic> map, String id) {
    return QuizResultModel(
      id: id,
      benevoleId: map['benevoleId'] ?? '',
      formationId: map['formationId'] ?? '',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      completedAt: (map['completedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      badgeObtenu: map['badgeObtenu'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'benevoleId': benevoleId,
      'formationId': formationId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt,
      'badgeObtenu': badgeObtenu,
    };
  }
}