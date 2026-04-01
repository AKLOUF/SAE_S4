import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/formation_model.dart';
import '../../models/session_model.dart';
import '../../services/formation_service.dart';
import '../../services/auth_service.dart';
import '../benevole/login_screen.dart';
import 'calendar_screen.dart';
import 'create_formation_screen.dart';
import 'impact_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
            automaticallyImplyLeading: false,
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
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Administration 🛠️',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Tableau de bord',
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
              // ── Bouton calendrier dans l'AppBar ────────
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined,
                    color: Colors.white),
                tooltip: 'Calendrier des sessions',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CalendarAdminScreen()),
                ),
              ),
              // ── Bouton impact programme ─────────────────
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white),
                tooltip: 'Impact du programme',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ImpactScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Déconnexion',
                onPressed: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ],
        body: const _StatsContent(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_formation',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateFormationScreen()),
        ),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle formation',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Contenu scrollable ────────────────────────────────────────────────────────

class _StatsContent extends StatelessWidget {
  const _StatsContent();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FormationModel>>(
      stream: FormationService().getAllFormations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }
        final formations = snapshot.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions')
              .snapshots(),
          builder: (context, sessSnap) {
            final Map<String, List<SessionModel>> sessionsMap = {};
            if (sessSnap.hasData) {
              for (final doc in sessSnap.data!.docs) {
                final s = SessionModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
                sessionsMap.putIfAbsent(s.formationId, () => []).add(s);
              }
            }
            return _StatsBody(
              formations: formations,
              sessionsMap: sessionsMap,
              allSessionDocs: sessSnap.data?.docs ?? [],
            );
          },
        );
      },
    );
  }
}

// ── Corps principal ────────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  final List<FormationModel> formations;
  final Map<String, List<SessionModel>> sessionsMap;
  final List<QueryDocumentSnapshot> allSessionDocs;

  const _StatsBody({
    required this.formations,
    required this.sessionsMap,
    required this.allSessionDocs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Bannière calendrier ────────────────────────
        _CalendarBanner(allSessionDocs: allSessionDocs),
        const SizedBox(height: 20),

        // ── Grille 4 compteurs temps réel ──────────────
        _AdminStatsGrid(),
        const SizedBox(height: 28),

        // ── Header liste formations ────────────────────
        Row(
          children: [
            const Icon(Icons.school_outlined,
                color: Color(0xFF00796B), size: 20),
            const SizedBox(width: 8),
            const Text('Formations',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const Spacer(),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${formations.length}',
                style: const TextStyle(
                    color: Color(0xFF00796B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (formations.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.school_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Aucune formation créée',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 15)),
              ],
            ),
          )
        else
          ...formations.map((f) => _FormationCard(
            formation: f,
            sessions: sessionsMap[f.id] ?? [],
          )),
      ],
    );
  }
}

// ── Bannière calendrier ────────────────────────────────────────────────────────

class _CalendarBanner extends StatelessWidget {
  final List<QueryDocumentSnapshot> allSessionDocs;

  const _CalendarBanner({required this.allSessionDocs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final sessionsCount = allSessionDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['date'];
      if (ts == null) return false;
      final date = (ts as Timestamp).toDate();
      return date.year == now.year && date.month == now.month;
    }).length;

    SessionModel? prochaine;
    for (final doc in allSessionDocs) {
      final s = SessionModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
      if (s.date.isAfter(now)) {
        if (prochaine == null || s.date.isBefore(prochaine.date)) {
          prochaine = s;
        }
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarAdminScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00796B), Color(0xFF004D40)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00796B).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.calendar_month_outlined,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calendrier des sessions',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    prochaine != null
                        ? 'Prochaine : ${prochaine.titre.isEmpty ? "Session" : prochaine.titre} · ${prochaine.date.day.toString().padLeft(2, '0')}/${prochaine.date.month.toString().padLeft(2, '0')}'
                        : 'Aucune session à venir',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$sessionsCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'ce mois',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.6), size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Grille 4 compteurs temps réel ─────────────────────────────────────────────

class _AdminStatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'benevole')
          .snapshots(),
      builder: (context, benevoleSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Formations')
              .snapshots(),
          builder: (context, formationSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'formateur')
                  .snapshots(),
              builder: (context, formateurSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sessions')
                      .snapshots(),
                  builder: (context, sessionSnap) {
                    final nbBenevoles =
                        benevoleSnap.data?.docs.length ?? 0;
                    final nbFormations =
                        formationSnap.data?.docs.length ?? 0;
                    final nbFormateurs =
                        formateurSnap.data?.docs.length ?? 0;
                    final nbSessions =
                        sessionSnap.data?.docs.length ?? 0;

                    final items = [
                      _StatData(
                        label: 'Bénévoles',
                        valeur: '$nbBenevoles',
                        icone: Icons.volunteer_activism_outlined,
                        couleur: const Color(0xFF7C3AED),
                      ),
                      _StatData(
                        label: 'Formations',
                        valeur: '$nbFormations',
                        icone: Icons.school_outlined,
                        couleur: const Color(0xFF00796B),
                      ),
                      _StatData(
                        label: 'Formateurs',
                        valeur: '$nbFormateurs',
                        icone: Icons.person_outline,
                        couleur: const Color(0xFF2563EB),
                      ),
                      _StatData(
                        label: 'Sessions',
                        valeur: '$nbSessions',
                        icone: Icons.event_outlined,
                        couleur: const Color(0xFFD97706),
                      ),
                    ];

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children:
                      items.map((s) => _StatCard(data: s)).toList(),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Carte stat ────────────────────────────────────────────────────────────────

class _StatData {
  final String label;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatData({
    required this.label,
    required this.valeur,
    required this.icone,
    required this.couleur,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icone, color: data.couleur, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.valeur,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: data.couleur)),
              Text(data.label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Carte formation avec ses sessions ─────────────────────────────────────────

class _FormationCard extends StatefulWidget {
  final FormationModel formation;
  final List<SessionModel> sessions;

  const _FormationCard({required this.formation, required this.sessions});

  @override
  State<_FormationCard> createState() => _FormationCardState();
}

class _FormationCardState extends State<_FormationCard> {
  bool _expanded = false;

  static const Map<String, Map<String, dynamic>> _thematiques = {
    'inclusion': {'couleur': Color(0xFF7C3AED), 'icone': Icons.people},
    'environnement': {'couleur': Color(0xFF059669), 'icone': Icons.eco},
    'egalite': {'couleur': Color(0xFFDC2626), 'icone': Icons.balance},
    'tolerance': {'couleur': Color(0xFFD97706), 'icone': Icons.handshake},
    'citoyennete': {
      'couleur': Color(0xFF2563EB),
      'icone': Icons.account_balance
    },
  };

  Color get _color {
    final t = widget.formation.categories.isNotEmpty
        ? widget.formation.categories.first
        : 'inclusion';
    return _thematiques[t]?['couleur'] as Color? ?? const Color(0xFF00796B);
  }

  IconData get _icon {
    final t = widget.formation.categories.isNotEmpty
        ? widget.formation.categories.first
        : 'inclusion';
    return _thematiques[t]?['icone'] as IconData? ?? Icons.school;
  }

  int get _totalPlaces =>
      widget.sessions.fold(0, (sum, s) => sum + s.maxParticipants);

  @override
  Widget build(BuildContext context) {
    final sessionCount = widget.sessions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.formation.titre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.formation.isActive
                                    ? const Color(0xFF00796B)
                                    .withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.formation.isActive
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: widget.formation.isActive
                                        ? const Color(0xFF00796B)
                                        : Colors.grey.shade500),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$sessionCount session${sessionCount > 1 ? 's' : ''}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.sessions.isNotEmpty)
                    _TauxBadgeLive(
                      sessions: widget.sessions,
                      totalPlaces: _totalPlaces,
                      couleur: _color,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            if (widget.sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('Aucune session pour cette formation',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: widget.sessions
                      .map((s) => _SessionRow(session: s, couleur: _color))
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Badge taux live ───────────────────────────────────────────────────────────

class _TauxBadgeLive extends StatefulWidget {
  final List<SessionModel> sessions;
  final int totalPlaces;
  final Color couleur;
  const _TauxBadgeLive(
      {required this.sessions,
        required this.totalPlaces,
        required this.couleur});

  @override
  State<_TauxBadgeLive> createState() => _TauxBadgeLiveState();
}

class _TauxBadgeLiveState extends State<_TauxBadgeLive> {
  final Map<String, int> _counts = {};

  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty || widget.totalPlaces == 0) {
      return const SizedBox.shrink();
    }
    return _buildNested(0);
  }

  Widget _buildNested(int index) {
    if (index >= widget.sessions.length) {
      final total = _counts.values.fold(0, (a, b) => a + b);
      final taux = (total / widget.totalPlaces) * 100;
      return _TauxBadge(taux: taux, couleur: widget.couleur);
    }
    final session = widget.sessions[index];
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(session.id)
          .collection('inscrits')
          .snapshots(),
      builder: (context, snap) {
        _counts[session.id] = snap.data?.docs.length ?? 0;
        return _buildNested(index + 1);
      },
    );
  }
}

// ── Badge taux de remplissage ──────────────────────────────────────────────────

class _TauxBadge extends StatelessWidget {
  final double taux;
  final Color couleur;
  const _TauxBadge({required this.taux, required this.couleur});

  Color get _badgeColor {
    if (taux >= 80) return const Color(0xFFDC2626);
    if (taux >= 50) return const Color(0xFFD97706);
    return const Color(0xFF00796B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('${taux.toStringAsFixed(0)}%',
          style: TextStyle(
              color: _badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ── Ligne session ──────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final SessionModel session;
  final Color couleur;
  const _SessionRow({required this.session, required this.couleur});

  static const Map<String, Map<String, dynamic>> _statutConfig = {
    'planifiee': {'label': 'Planifiée', 'couleur': Color(0xFF2563EB)},
    'en_cours': {'label': 'En cours', 'couleur': Color(0xFFD97706)},
    'terminee': {'label': 'Terminée', 'couleur': Color(0xFF00796B)},
  };

  @override
  Widget build(BuildContext context) {
    final config =
        _statutConfig[session.statut] ?? _statutConfig['planifiee']!;
    final statutColor = config['couleur'] as Color;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(session.id)
          .collection('inscrits')
          .snapshots(),
      builder: (context, inscritSnap) {
        final nbInscrits = inscritSnap.data?.docs.length ?? 0;
        final max = session.maxParticipants;
        final taux = max == 0 ? 0.0 : (nbInscrits / max) * 100;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: couleur.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.titre.isEmpty
                          ? 'Session sans titre'
                          : session.titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A1A2E)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statutColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(config['label'] as String,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statutColor)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                      '${session.date.day}/${session.date.month}/${session.date.year}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: taux >= 80
                            ? const Color(0xFFDC2626)
                            : taux >= 50
                            ? const Color(0xFFD97706)
                            : const Color(0xFF00796B),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$nbInscrits/$max',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}