import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CertificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Vérifie si le bénévole a réussi tous les quiz d'une thématique ──
  Future<bool> verifierCertification({
    required String uid,
    required String thematique,
  }) async {
    final formationsSnap = await _db
        .collection('Formations')
        .where('thematique', isEqualTo: thematique)
        .where('isActive', isEqualTo: true)
        .get();

    if (formationsSnap.docs.isEmpty) return false;

    final formationIds = formationsSnap.docs.map((d) => d.id).toList();

    final badgesSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('badges')
        .get();

    final badgesObtenus = badgesSnap.docs.map((d) => d.id).toSet();
    return formationIds.every((id) => badgesObtenus.contains(id));
  }

  // ── Récupère la progression par thématique ──────────────────────────
  Future<Map<String, dynamic>> getProgression({
    required String uid,
    required String thematique,
  }) async {
    final formationsSnap = await _db
        .collection('Formations')
        .where('thematique', isEqualTo: thematique)
        .where('isActive', isEqualTo: true)
        .get();

    final totalFormations = formationsSnap.docs.length;
    if (totalFormations == 0) {
      return {'total': 0, 'reussis': 0, 'pourcentage': 0.0};
    }

    final formationIds = formationsSnap.docs.map((d) => d.id).toList();

    final badgesSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('badges')
        .get();

    final badgesObtenus = badgesSnap.docs.map((d) => d.id).toSet();
    final reussis =
        formationIds.where((id) => badgesObtenus.contains(id)).length;

    return {
      'total': totalFormations,
      'reussis': reussis,
      'pourcentage': (reussis / totalFormations) * 100,
      'formations': formationsSnap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'titre': data['titre'] ?? '',
          'reussi': badgesObtenus.contains(d.id),
        };
      }).toList(),
    };
  }

  // ── Soumet une demande de certification ─────────────────────────────
  // Statuts : 'en_attente' | 'validee' | 'refusee'
  Future<void> demanderCertification({
    required String uid,
    required String thematique,
    required String nomBenevole,
    required String emailBenevole,
  }) async {
    // Vérifie que les critères sont remplis
    final eligible = await verifierCertification(
        uid: uid, thematique: thematique);
    if (!eligible) throw 'Critères non remplis pour cette certification.';

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('certifications')
        .doc(thematique);

    final snap = await ref.get();

    // Ne crée pas en double si déjà soumise ou obtenue
    if (snap.exists) {
      final statut = snap.data()?['statut'] ?? '';
      if (statut == 'validee') throw 'Certification déjà obtenue.';
      if (statut == 'en_attente') throw 'Demande déjà en cours de validation.';
    }

    final now = FieldValue.serverTimestamp();

    // Enregistre la demande dans le profil du bénévole
    await ref.set({
      'thematique': thematique,
      'statut': 'en_attente',
      'dateDemande': now,
      'dateValidation': null,
      'adminId': null,
      'nomBenevole': nomBenevole,
      'emailBenevole': emailBenevole,
      'benevoleId': uid,
    });

    // Enregistre aussi dans la collection globale pour que l'admin voie tout
    await _db.collection('certifications_demandes').doc('${uid}_$thematique').set({
      'benevoleId': uid,
      'nomBenevole': nomBenevole,
      'emailBenevole': emailBenevole,
      'thematique': thematique,
      'statut': 'en_attente',
      'dateDemande': now,
      'dateValidation': null,
      'adminId': null,
    });
  }

  // ── Récupère le statut d'une certification pour un bénévole ─────────
  Future<String?> getCertificationStatut({
    required String uid,
    required String thematique,
  }) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('certifications')
        .doc(thematique)
        .get();
    if (!snap.exists) return null;
    return snap.data()?['statut'] as String?;
  }

  // ── Stream statut certification (temps réel) ─────────────────────────
  Stream<DocumentSnapshot> getCertificationStream({
    required String uid,
    required String thematique,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('certifications')
        .doc(thematique)
        .snapshots();
  }

  // ── Admin : stream toutes les demandes en attente ────────────────────
  Stream<QuerySnapshot> getDemandesEnAttente() {
    return _db
        .collection('certifications_demandes')
        .where('statut', isEqualTo: 'en_attente')
        .orderBy('dateDemande', descending: false)
        .snapshots();
  }

  // ── Admin : stream toutes les demandes (historique) ──────────────────
  Stream<QuerySnapshot> getToutesLesDemandes() {
    return _db
        .collection('certifications_demandes')
        .orderBy('dateDemande', descending: true)
        .snapshots();
  }

  // ── Admin : valide une certification ────────────────────────────────
  Future<void> validerCertification({
    required String benevoleId,
    required String thematique,
  }) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    // Met à jour dans le profil du bénévole
    final certifRef = _db
        .collection('users')
        .doc(benevoleId)
        .collection('certifications')
        .doc(thematique);
    batch.update(certifRef, {
      'statut': 'validee',
      'dateValidation': now,
      'adminId': adminId,
    });

    // Met à jour dans la collection globale
    final demandeRef = _db
        .collection('certifications_demandes')
        .doc('${benevoleId}_$thematique');
    batch.update(demandeRef, {
      'statut': 'validee',
      'dateValidation': now,
      'adminId': adminId,
    });

    // Ajoute un badge spécial certification dans le profil du bénévole
    final badgeRef = _db
        .collection('users')
        .doc(benevoleId)
        .collection('badges')
        .doc('certif_$thematique');
    batch.set(badgeRef, {
      'titre': 'Certification ${_capitaliser(thematique)}',
      'type': 'certification',
      'thematique': thematique,
      'date_obtention': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ── Admin : refuse une certification ────────────────────────────────
  Future<void> refuserCertification({
    required String benevoleId,
    required String thematique,
    String motif = '',
  }) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    final certifRef = _db
        .collection('users')
        .doc(benevoleId)
        .collection('certifications')
        .doc(thematique);
    batch.update(certifRef, {
      'statut': 'refusee',
      'dateValidation': now,
      'adminId': adminId,
      'motifRefus': motif,
    });

    final demandeRef = _db
        .collection('certifications_demandes')
        .doc('${benevoleId}_$thematique');
    batch.update(demandeRef, {
      'statut': 'refusee',
      'dateValidation': now,
      'adminId': adminId,
      'motifRefus': motif,
    });

    await batch.commit();
  }

  // ── Récupère toutes les certifications obtenues ──────────────────────
  Stream<QuerySnapshot> getCertifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('certifications')
        .snapshots();
  }

  String _capitaliser(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}