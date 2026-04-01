import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Modèle de données agrégées ─────────────────────────────────────────────────
class _ImpactData {
  final int totalInscrits;
  final int totalPresents;
  final int totalQuiz;
  final int totalQuizReussis;
  final int totalBenevoles;
  final int benevolesAvecSessionComplete;
  final int totalCertifications;
  final List<Map<String, dynamic>> topFormations;

  const _ImpactData({
    required this.totalInscrits,
    required this.totalPresents,
    required this.totalQuiz,
    required this.totalQuizReussis,
    required this.totalBenevoles,
    required this.benevolesAvecSessionComplete,
    required this.totalCertifications,
    required this.topFormations,
  });

  double get tauxParticipation =>
      totalInscrits == 0 ? 0 : (totalPresents / totalInscrits) * 100;

  double get tauxReussiteQuiz =>
      totalQuiz == 0 ? 0 : (totalQuizReussis / totalQuiz) * 100;

  double get tauxProgressionBenevoles =>
      totalBenevoles == 0
          ? 0
          : (benevolesAvecSessionComplete / totalBenevoles) * 100;
}

// ── Écran principal ────────────────────────────────────────────────────────────
class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  _ImpactData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = FirebaseFirestore.instance;

      // ── 1. Participation : sessions + inscrits + présents ──────────
      final sessionsSnap = await db.collection('sessions').get();
      int totalInscrits = 0;
      int totalPresents = 0;
      final Map<String, Map<String, dynamic>> formationStats = {};

      for (final sessionDoc in sessionsSnap.docs) {
        final sData = sessionDoc.data();
        final formationId = sData['formationId'] as String? ?? '';
        final formationTitre = sData['formationTitre'] as String? ??
            sData['formation'] as String? ??
            'Sans titre';

        final inscritsSnap = await db
            .collection('sessions')
            .doc(sessionDoc.id)
            .collection('inscrits')
            .get();

        final inscrits = inscritsSnap.docs.length;
        final presents = inscritsSnap.docs
            .where((d) => (d.data()['present'] ?? false) == true)
            .length;

        totalInscrits += inscrits;
        totalPresents += presents;

        if (formationId.isNotEmpty) {
          if (!formationStats.containsKey(formationId)) {
            formationStats[formationId] = {
              'titre': formationTitre,
              'inscrits': 0,
              'presents': 0,
            };
          }
          formationStats[formationId]!['inscrits'] =
              (formationStats[formationId]!['inscrits'] as int) + inscrits;
          formationStats[formationId]!['presents'] =
              (formationStats[formationId]!['presents'] as int) + presents;
        }
      }

      final topFormations = formationStats.entries
          .map((e) => {'formationId': e.key, ...e.value})
          .toList()
        ..sort((a, b) =>
            (b['inscrits'] as int).compareTo(a['inscrits'] as int));
      final top5 = topFormations.take(5).toList();

      // ── 2. Bénévoles ──────────────────────────────────────────────
      final benevolesSnap = await db
          .collection('users')
          .where('role', isEqualTo: 'benevole')
          .get();
      final totalBenevoles = benevolesSnap.docs.length;

      // ── 3. Quiz : lire depuis users/{uid}/quiz_results ────────────
      // C'est là que QuizScreen sauvegarde (pas dans une collection racine)
      int totalQuiz = 0;
      int totalQuizReussis = 0;
      int benevolesAvecSessionComplete = 0;
      int totalCertifications = 0;

      for (final bDoc in benevolesSnap.docs) {
        // Quiz results
        final quizSnap = await db
            .collection('users')
            .doc(bDoc.id)
            .collection('quiz_results')
            .get();

        totalQuiz += quizSnap.docs.length;
        // Réussi = score >= 70 (champ 'score' enregistré par QuizScreen)
        totalQuizReussis += quizSnap.docs
            .where((d) => ((d.data()['score'] as num?)?.toDouble() ?? 0) >= 70)
            .length;

        // Bénévoles ayant au moins un badge de participation
        final badgesSnap = await db
            .collection('users')
            .doc(bDoc.id)
            .collection('badges')
            .where('type', isEqualTo: 'participation')
            .limit(1)
            .get();
        if (badgesSnap.docs.isNotEmpty) benevolesAvecSessionComplete++;

        // Certifications
        final certifSnap = await db
            .collection('users')
            .doc(bDoc.id)
            .collection('certifications')
            .get();
        totalCertifications += certifSnap.docs.length;
      }

      if (mounted) {
        setState(() {
          _data = _ImpactData(
            totalInscrits: totalInscrits,
            totalPresents: totalPresents,
            totalQuiz: totalQuiz,
            totalQuizReussis: totalQuizReussis,
            totalBenevoles: totalBenevoles,
            benevolesAvecSessionComplete: benevolesAvecSessionComplete,
            totalCertifications: totalCertifications,
            topFormations: top5,
          );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF00796B),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00796B), Color(0xFF004D40)],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(72, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Administration 📊',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Impact du programme',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Actualiser',
                onPressed: _loadData,
              ),
            ],
          ),
        ],
        body: _loading
            ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF00796B)),
              SizedBox(height: 16),
              Text('Chargement des données...',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        )
            : _error != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erreur : $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          color: const Color(0xFF00796B),
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Section participation ──────────────────
              _SectionTitle(
                icone: Icons.people_outline,
                label: 'Participation',
                couleur: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    label: 'Inscrits',
                    valeur: '${_data!.totalInscrits}',
                    icone: Icons.person_add_outlined,
                    couleur: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Présents',
                    valeur: '${_data!.totalPresents}',
                    icone: Icons.how_to_reg_outlined,
                    couleur: const Color(0xFF00796B),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _TauxBar(
                label: 'Taux de participation',
                taux: _data!.tauxParticipation,
                detail:
                '${_data!.totalPresents} présents sur ${_data!.totalInscrits} inscrits',
                couleur: const Color(0xFF2563EB),
              ),

              const SizedBox(height: 28),

              // ── Section quiz ───────────────────────────
              _SectionTitle(
                icone: Icons.quiz_outlined,
                label: 'Quiz',
                couleur: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    label: 'Quiz passés',
                    valeur: '${_data!.totalQuiz}',
                    icone: Icons.assignment_outlined,
                    couleur: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Réussis',
                    valeur: '${_data!.totalQuizReussis}',
                    icone: Icons.check_circle_outline,
                    couleur: const Color(0xFF059669),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _TauxBar(
                label: 'Taux de réussite',
                taux: _data!.tauxReussiteQuiz,
                detail:
                '${_data!.totalQuizReussis} réussis sur ${_data!.totalQuiz} quiz',
                couleur: const Color(0xFF7C3AED),
              ),

              const SizedBox(height: 28),

              // ── Section progression bénévoles ──────────
              _SectionTitle(
                icone: Icons.trending_up_outlined,
                label: 'Progression bénévoles',
                couleur: const Color(0xFFD97706),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    label: 'Bénévoles',
                    valeur: '${_data!.totalBenevoles}',
                    icone: Icons.group_outlined,
                    couleur: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Actifs',
                    valeur:
                    '${_data!.benevolesAvecSessionComplete}',
                    icone: Icons.workspace_premium_outlined,
                    couleur: const Color(0xFFDC2626),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _TauxBar(
                label: 'Bénévoles ayant complété une session',
                taux: _data!.tauxProgressionBenevoles,
                detail:
                '${_data!.benevolesAvecSessionComplete} sur ${_data!.totalBenevoles} bénévoles',
                couleur: const Color(0xFFD97706),
              ),

              const SizedBox(height: 28),

              // ── Section certifications ─────────────────
              _SectionTitle(
                icone: Icons.workspace_premium_outlined,
                label: 'Certifications',
                couleur: const Color(0xFF059669),
              ),
              const SizedBox(height: 12),
              _StatCardLarge(
                label: 'Certifications obtenues',
                valeur: '${_data!.totalCertifications}',
                icone: Icons.card_membership_outlined,
                couleur: const Color(0xFF059669),
                sousTitre: 'Toutes thématiques confondues',
              ),

              const SizedBox(height: 28),

              // ── Top formations ─────────────────────────
              _SectionTitle(
                icone: Icons.star_outline,
                label: 'Top formations',
                couleur: const Color(0xFF00796B),
              ),
              const SizedBox(height: 12),

              if (_data!.topFormations.isEmpty)
                _EmptyState(
                  icone: Icons.school_outlined,
                  message: 'Aucune formation avec participants',
                )
              else
                ..._data!.topFormations.asMap().entries.map(
                      (entry) => _TopFormationRow(
                    rang: entry.key + 1,
                    titre: entry.value['titre'] as String? ??
                        'Formation',
                    inscrits:
                    entry.value['inscrits'] as int? ?? 0,
                    presents:
                    entry.value['presents'] as int? ?? 0,
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color couleur;

  const _SectionTitle({
    required this.icone,
    required this.label,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: couleur, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Icon(icone, color: couleur, size: 18),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: couleur)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatCard({
    required this.label,
    required this.valeur,
    required this.icone,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icone, color: couleur, size: 16),
          ),
          const SizedBox(height: 10),
          Text(valeur,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: couleur)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatCardLarge extends StatelessWidget {
  final String label;
  final String valeur;
  final IconData icone;
  final Color couleur;
  final String sousTitre;

  const _StatCardLarge({
    required this.label,
    required this.valeur,
    required this.icone,
    required this.couleur,
    required this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: couleur, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valeur,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: couleur)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                Text(sousTitre,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TauxBar extends StatelessWidget {
  final String label;
  final double taux;
  final String detail;
  final Color couleur;

  const _TauxBar({
    required this.label,
    required this.taux,
    required this.detail,
    required this.couleur,
  });

  Color get _barColor {
    if (taux >= 75) return const Color(0xFF059669);
    if (taux >= 50) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              Text(
                '${taux.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _barColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (taux / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: _barColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(detail,
              style:
              TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _TopFormationRow extends StatelessWidget {
  final int rang;
  final String titre;
  final int inscrits;
  final int presents;

  const _TopFormationRow({
    required this.rang,
    required this.titre,
    required this.inscrits,
    required this.presents,
  });

  double get _tauxPresence =>
      inscrits == 0 ? 0 : (presents / inscrits) * 100;

  Color get _rangColor {
    switch (rang) {
      case 1:
        return const Color(0xFFD97706);
      case 2:
        return const Color(0xFF6B7280);
      case 3:
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF00796B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _rangColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#$rang',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _rangColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_tauxPresence / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    color: _rangColor,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$inscrits inscrits',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              Text('${_tauxPresence.toStringAsFixed(0)}% présents',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icone;
  final String message;
  const _EmptyState({required this.icone, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icone, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}