import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/formation_model.dart';
import '../models/session_model.dart';

class FormationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'Formations';
  final String _sessionsCollection = 'sessions'; // collection racine

  // ─── FORMATIONS ───────────────────────────────────────────────

  /// Stream catalogue actif (bénévoles)
  Stream<List<FormationModel>> getCatalogue() {
    return _db
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => FormationModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Stream toutes les formations (admin / formateur)
  Stream<List<FormationModel>> getAllFormations() {
    return _db
        .collection(_collection)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => FormationModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// Récupère une formation par ID
  Future<FormationModel?> getFormation(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return FormationModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Crée une formation — retourne l'ID créé
  Future<String> createFormation({
    required String titre,
    required String description,
    required String thematique,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ref = await _db.collection(_collection).add({
      'titre': titre,
      'description': description,
      'thematique': thematique,
      'formateurId': uid,
      'dateCreation': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return ref.id;
  }

  /// Modifie une formation existante
  Future<void> updateFormation(
      String formationId, {
        String? titre,
        String? description,
        String? thematique,
      }) async {
    final data = <String, dynamic>{};
    if (titre != null) data['titre'] = titre;
    if (description != null) data['description'] = description;
    if (thematique != null) data['thematique'] = thematique;
    if (data.isEmpty) return;
    await _db.collection(_collection).doc(formationId).update(data);
  }

  /// Active / désactive une formation
  Future<void> toggleActive(String formationId, bool isActive) async {
    await _db
        .collection(_collection)
        .doc(formationId)
        .update({'isActive': isActive});
  }

  /// Supprime une formation
  Future<void> deleteFormation(String formationId) async {
    await _db.collection(_collection).doc(formationId).delete();
  }

  // ─── SESSIONS (collection racine) ─────────────────────────────

  /// Stream toutes les sessions (formateur / admin)
  Stream<List<SessionModel>> getAllSessionsStream() {
    return _db
        .collection(_sessionsCollection)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => SessionModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Stream sessions d'une formation
  Stream<List<SessionModel>> getSessionsStream(String formationId) {
    return _db
        .collection(_sessionsCollection)
        .where('formationId', isEqualTo: formationId)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => SessionModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Stream sessions d'un formateur
  Stream<List<SessionModel>> getSessionsFormateur(String formateurId) {
    return _db
        .collection(_sessionsCollection)
        .where('formateurId', isEqualTo: formateurId)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => SessionModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Ajoute une session dans la collection racine
  Future<String> addSession(SessionModel session) async {
    final ref = await _db
        .collection(_sessionsCollection)
        .add(session.toMap());
    return ref.id;
  }

  /// Modifie une session
  Future<void> updateSession(
      String sessionId, Map<String, dynamic> data) async {
    await _db
        .collection(_sessionsCollection)
        .doc(sessionId)
        .update(data);
  }

  /// Supprime une session
  Future<void> deleteSession(String sessionId) async {
    await _db
        .collection(_sessionsCollection)
        .doc(sessionId)
        .delete();
  }

  // ─── FORMATEURS ───────────────────────────────────────────────

  /// Récupère la liste des formateurs depuis users
  Future<List<Map<String, dynamic>>> getFormateurs() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'formateur')
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'nom': data['nom'] ?? data['displayName'] ?? 'Formateur',
        'email': data['email'] ?? '',
      };
    }).toList();
  }
}