import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_result_model.dart';
import '../models/badge_model.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const double _seuilBadge = 70.0;

  // --- ACTIONS ---

  Future<void> soumettreQuiz({
    required String benevoleId,
    required String formationId,
    required String titreFormation,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final double pourcentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
      final bool estReussi = pourcentage >= _seuilBadge;

      final batch = _db.batch();

      // 1. Résultat du quiz
      final resultRef = _db.collection('quiz_results').doc();
      batch.set(resultRef, {
        'benevoleId': benevoleId,
        'formationId': formationId,
        'titreFormation': titreFormation,
        'score': score,
        'totalQuestions': totalQuestions,
        'completedAt': FieldValue.serverTimestamp(),
        'badgeObtenu': estReussi,
      });

      // 2. Badge si réussite
      if (estReussi) {
        final badgeRef = _db.collection('badges').doc('${benevoleId}_$formationId');
        batch.set(badgeRef, {
          'benevoleId': benevoleId,
          'formationId': formationId,
          'titre': titreFormation,
          'description': 'Validé avec ${pourcentage.toStringAsFixed(0)}%',
          'obtenuLe': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw 'Erreur QuizService: $e';
    }
  }

  // --- LECTURE (Corrigé pour utiliser fromMap) ---

  Stream<List<QuizResultModel>> getResultatsByBenevole(String benevoleId) {
    return _db
        .collection('quiz_results')
        .where('benevoleId', isEqualTo: benevoleId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => QuizResultModel.fromMap(doc.data(), doc.id)) // Changé ici
        .toList());
  }

  Stream<List<BadgeModel>> getBadgesByBenevole(String benevoleId) {
    return _db
        .collection('badges')
        .where('benevoleId', isEqualTo: benevoleId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => BadgeModel.fromMap(doc.data(), doc.id)) // Changé ici
        .toList());
  }
}