import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/session_model.dart';
import '../../services/notification_service.dart';

class SessionsBenevoleScreen extends StatelessWidget {
  const SessionsBenevoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF00796B),
            // ── CORRECTION : on gère le leading manuellement pour
            // éviter l'écrasement sur le texte
            automaticallyImplyLeading: false,
            leading: Navigator.canPop(context)
                ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00796B), Color(0xFF004D40)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    // ── CORRECTION : padding gauche augmenté quand
                    // le bouton retour est présent (56 = largeur du leading)
                    padding: EdgeInsets.fromLTRB(
                      Navigator.canPop(context) ? 56 : 20,
                      16,
                      20,
                      0,
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Mon espace',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Sessions disponibles',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sessions')
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00796B))),
                );
              }

              if (snapshot.hasError) {
                // Fallback sans orderBy si index manquant
                return _SessionsListWithoutOrder(uid: uid);
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 80,
                            color: const Color(0xFF00796B)
                                .withValues(alpha: 0.15)),
                        const SizedBox(height: 16),
                        const Text('Aucune session disponible',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final data =
                      docs[i].data() as Map<String, dynamic>;
                      final session =
                      SessionModel.fromMap(data, docs[i].id);
                      return _SessionCardBenevole(
                        session: session,
                        currentUid: uid,
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Fallback sans orderBy (si index Firestore manquant) ───────────────────────
class _SessionsListWithoutOrder extends StatelessWidget {
  final String uid;
  const _SessionsListWithoutOrder({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('Aucune session disponible')),
          );
        }
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final da = (a.data() as Map)['date'];
            final db = (b.data() as Map)['date'];
            if (da is Timestamp && db is Timestamp) {
              return da.compareTo(db);
            }
            return 0;
          });

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final session = SessionModel.fromMap(data, docs[i].id);
                return _SessionCardBenevole(
                    session: session, currentUid: uid);
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }
}

// ── Card session bénévole ──────────────────────────────────────────────────────
class _SessionCardBenevole extends StatelessWidget {
  final SessionModel session;
  final String currentUid;

  const _SessionCardBenevole({
    required this.session,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ─────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          session.titre.isEmpty ? 'Session' : session.titre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      if (session.formationTitre.isNotEmpty)
                        Text(session.formationTitre,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.estComplet
                        ? Colors.red.withValues(alpha: 0.1)
                        : const Color(0xFF00796B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.estComplet
                        ? 'Complet'
                        : '${session.placesRestantes} places',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: session.estComplet
                          ? Colors.red
                          : const Color(0xFF00796B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icone: Icons.calendar_today_outlined,
                  label:
                  '${session.date.day.toString().padLeft(2, '0')}/${session.date.month.toString().padLeft(2, '0')}/${session.date.year}',
                ),
                if (session.heureDebut.isNotEmpty)
                  _InfoChip(
                    icone: Icons.schedule_outlined,
                    label: session.heureFin.isNotEmpty
                        ? '${session.heureDebut} → ${session.heureFin}'
                        : session.heureDebut,
                  ),
                if (session.formateurNom.isNotEmpty)
                  _InfoChip(
                    icone: Icons.person_outline,
                    label: session.formateurNom,
                  ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Bouton inscription ────────────────────────────
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .doc(session.id)
                  .collection('inscrits')
                  .doc(currentUid)
                  .snapshots(),
              builder: (context, inscritSnap) {
                final dejaInscrit = inscritSnap.data?.exists ?? false;

                if (dejaInscrit) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00796B)
                              .withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFF00796B), size: 18),
                        SizedBox(width: 8),
                        Text('Vous êtes inscrit ✓',
                            style: TextStyle(
                                color: Color(0xFF00796B),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                if (session.estComplet) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Session complète',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _sInscrire(context),
                    icon: const Icon(Icons.how_to_reg_outlined,
                        color: Colors.white, size: 18),
                    label: const Text("S'inscrire à cette session",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sInscrire(BuildContext context) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final nom = userData['nom'] ?? '';
      final email = userData['email'] ?? '';

      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(session.id)
          .collection('inscrits')
          .doc(currentUid)
          .set({
        'nom': nom,
        'email': email,
        'present': false,
        'inscritLe': FieldValue.serverTimestamp(),
      });

      await NotificationService.planifierRappel(
        sessionId: session.id,
        titreSession: session.titre,
        dateSession: session.date,
      );

      await NotificationService.envoyerNotificationTest(
          titreSession: session.titre);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inscription réussie ! ✓'),
              backgroundColor: Color(0xFF00796B)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── Chip info ──────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icone;
  final String label;
  const _InfoChip({required this.icone, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}