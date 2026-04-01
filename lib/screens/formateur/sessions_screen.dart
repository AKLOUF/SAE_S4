import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/session_model.dart';
import '../../services/auth_service.dart';
import '../../services/formation_service.dart';
import '../benevole/login_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final authService = AuthService();

    debugPrint('▶ SessionsScreen uid = "$uid"');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirAjoutSession(context, uid),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une session',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
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
                        Text('Espace formateur',
                            style:
                            TextStyle(color: Colors.white70, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Mes sessions',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 26),
                onPressed: () async {
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                  }
                },
              ),
            ],
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sessions')
                .where('formateurId', isEqualTo: uid)
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
                debugPrint('❌ Firestore error: ${snapshot.error}');
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 60, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          const Text('Erreur de chargement',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
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
                        const Text('Aucune session',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 8),
                        Text('Vos sessions apparaîtront ici',
                            style:
                            TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final dateA = dataA['date'];
                final dateB = dataB['date'];
                if (dateA == null || dateB == null) return 0;
                if (dateA is Timestamp && dateB is Timestamp) {
                  return dateA.compareTo(dateB);
                }
                return 0;
              });

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final data =
                      docs[i].data() as Map<String, dynamic>;
                      final session =
                      SessionModel.fromMap(data, docs[i].id);
                      return _SessionCardFormateur(session: session);
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

  Future<void> _ouvrirAjoutSession(
      BuildContext context, String formateurUid) async {
    final session = await showModalBottomSheet<SessionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSessionSheet(
        couleur: const Color(0xFF00796B),
        formateurUid: formateurUid,
      ),
    );

    if (session != null && context.mounted) {
      try {
        await FormationService().addSession(session);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Session ajoutée avec succès !'),
              backgroundColor: Color(0xFF00796B)),
        );
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
}

// ── Card session formateur ─────────────────────────────────────────────────────

class _SessionCardFormateur extends StatefulWidget {
  final SessionModel session;
  const _SessionCardFormateur({required this.session});

  @override
  State<_SessionCardFormateur> createState() =>
      _SessionCardFormateurState();
}

class _SessionCardFormateurState extends State<_SessionCardFormateur> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                        Text(s.titre.isEmpty ? 'Session' : s.titre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        if (s.formationTitre.isNotEmpty)
                          Text(s.formationTitre,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            _InfoChip(
                              icone: Icons.calendar_today_outlined,
                              label:
                              '${s.date.day.toString().padLeft(2, '0')}/${s.date.month.toString().padLeft(2, '0')}/${s.date.year}',
                            ),
                            if (s.heureDebut.isNotEmpty)
                              _InfoChip(
                                icone: Icons.schedule_outlined,
                                label: s.heureFin.isNotEmpty
                                    ? '${s.heureDebut} → ${s.heureFin}'
                                    : s.heureDebut,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${s.maxParticipants} max',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00796B),
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InscritsList(sessionId: widget.session.id),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _DialogParticipants(
                              sessionId: widget.session.id),
                        ),
                        icon: const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 18),
                        label: const Text('Participants'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00796B),
                          side: const BorderSide(
                              color: Color(0xFF00796B)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('sessions')
                              .doc(widget.session.id)
                              .delete();
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 18),
                        label: const Text('Supprimer',
                            style:
                            TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
        Icon(icone, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(label,
            style:
            TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ── Liste inscrits ─────────────────────────────────────────────────────────────

class _InscritsList extends StatelessWidget {
  final String sessionId;
  const _InscritsList({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('inscrits')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) {
          return Row(children: [
            const Icon(Icons.people_outline,
                size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('Aucun participant inscrit',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13)),
          ]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.people_outline,
                  size: 16, color: Color(0xFF00796B)),
              const SizedBox(width: 6),
              Text('$count participant(s)',
                  style: const TextStyle(
                      color: Color(0xFF00796B),
                      fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 8),
            ...snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final present = d['present'] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: present
                        ? const Color(0xFF00796B)
                        : const Color(0xFF00796B)
                        .withValues(alpha: 0.1),
                    child: present
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                        : Text(
                      (d['nom'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF00796B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(d['nom'] ?? '',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  if (present)
                    const Text('🏆',
                        style: TextStyle(fontSize: 14)),
                ]),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Dialog participants ────────────────────────────────────────────────────────

class _DialogParticipants extends StatefulWidget {
  final String sessionId;
  const _DialogParticipants({required this.sessionId});

  @override
  State<_DialogParticipants> createState() =>
      _DialogParticipantsState();
}

class _DialogParticipantsState extends State<_DialogParticipants>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFE0F2EF)]),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFF00796B)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.group_add_outlined,
                        color: Color(0xFF00796B), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Participants',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                ]),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF00796B),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF00796B),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Ajouter'),
                    Tab(text: 'Présence')
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _OngletAjouter(sessionId: widget.sessionId),
                _OngletPresence(sessionId: widget.sessionId),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0F2EF), Colors.white]),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer',
                    style: TextStyle(
                        color: Color(0xFF00796B),
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet Ajouter ────────────────────────────────────────────────────────────

class _OngletAjouter extends StatefulWidget {
  final String sessionId;
  const _OngletAjouter({required this.sessionId});
  @override
  State<_OngletAjouter> createState() => _OngletAjouterState();
}

class _OngletAjouterState extends State<_OngletAjouter> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FDFB),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (v) =>
                setState(() => _recherche = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou email...',
              prefixIcon:
              const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.grey.shade200)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'benevole')
                  .snapshots(),
              builder: (context, usersSnap) {
                if (!usersSnap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00796B)));
                }
                final benevoles =
                usersSnap.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final nom =
                  (d['nom'] ?? '').toString().toLowerCase();
                  final email =
                  (d['email'] ?? '').toString().toLowerCase();
                  return nom.contains(_recherche) ||
                      email.contains(_recherche);
                }).toList();

                if (benevoles.isEmpty) {
                  return Center(
                      child: Text('Aucun bénévole trouvé',
                          style: TextStyle(
                              color: Colors.grey.shade500)));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sessions')
                      .doc(widget.sessionId)
                      .collection('inscrits')
                      .snapshots(),
                  builder: (context, inscritsSnap) {
                    final inscritsIds = inscritsSnap.data?.docs
                        .map((d) => d.id)
                        .toSet() ??
                        {};
                    return ListView.separated(
                      itemCount: benevoles.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                      itemBuilder: (context, i) {
                        final doc = benevoles[i];
                        final d =
                        doc.data() as Map<String, dynamic>;
                        final nom = d['nom'] ?? '';
                        final email = d['email'] ?? '';
                        final initiale = nom.isNotEmpty
                            ? nom[0].toUpperCase()
                            : '?';
                        final dejaInscrit =
                        inscritsIds.contains(doc.id);
                        return ListTile(
                          contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          leading: CircleAvatar(
                            backgroundColor: dejaInscrit
                                ? Colors.grey.shade300
                                : const Color(0xFF00796B),
                            child: Text(initiale,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(nom,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          subtitle: Text(email,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12)),
                          trailing: dejaInscrit
                              ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius:
                                  BorderRadius.circular(20)),
                              child: Text('Inscrit',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13)))
                              : ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('sessions')
                                  .doc(widget.sessionId)
                                  .collection('inscrits')
                                  .doc(doc.id)
                                  .set({
                                'nom': nom,
                                'email': email,
                                'present': false,
                                'inscritLe':
                                FieldValue.serverTimestamp(),
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF00796B),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              elevation: 0,
                            ),
                            child: const Text('Ajouter',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13)),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet Présence ───────────────────────────────────────────────────────────

class _OngletPresence extends StatelessWidget {
  final String sessionId;
  const _OngletPresence({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FDFB),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .collection('inscrits')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF00796B)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 60,
                      color: const Color(0xFF00796B)
                          .withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('Aucun participant inscrit',
                      style:
                      TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final nom = d['nom'] ?? '';
              final present = d['present'] ?? false;
              final initiale =
              nom.isNotEmpty ? nom[0].toUpperCase() : '?';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: present
                      ? const Color(0xFF00796B).withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: present
                        ? const Color(0xFF00796B)
                        .withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: present
                        ? const Color(0xFF00796B)
                        : Colors.grey.shade300,
                    child: present
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 20)
                        : Text(initiale,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(nom,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: present
                              ? const Color(0xFF00796B)
                              : const Color(0xFF1A1A2E))),
                  subtitle: Text(
                      present
                          ? 'Présent ✓'
                          : 'En attente de validation',
                      style: TextStyle(
                          fontSize: 12,
                          color: present
                              ? const Color(0xFF00796B)
                              : Colors.grey.shade500)),
                  trailing: present
                      ? const Text('🏆',
                      style: TextStyle(fontSize: 22))
                      : ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('sessions')
                          .doc(sessionId)
                          .collection('inscrits')
                          .doc(doc.id)
                          .update({'present': true});
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc.id)
                          .collection('badges')
                          .add({
                        'titre': 'Participation validée',
                        'sessionId': sessionId,
                        'date_obtention':
                        FieldValue.serverTimestamp(),
                        'type': 'participation',
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 0,
                    ),
                    child: const Text('Valider',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Bottom sheet ajout de session ──────────────────────────────────────────────

class _AddSessionSheet extends StatefulWidget {
  final Color couleur;
  final String formateurUid;
  const _AddSessionSheet(
      {required this.couleur, required this.formateurUid});

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  final _titreCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _heureDebut = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _heureFin = const TimeOfDay(hour: 11, minute: 0);
  int _maxParticipants = 20;
  String? _formationId;
  String _formationTitre = '';
  List<Map<String, dynamic>> _formations = [];
  bool _loadingFormations = true;

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    final snap = await FirebaseFirestore.instance
        .collection('Formations')
        .where('isActive', isEqualTo: true)
        .get();
    if (mounted) {
      setState(() {
        _formations = snap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'titre': d['titre'] ?? '',
          };
        }).toList();
        _loadingFormations = false;
      });
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
            ColorScheme.light(primary: widget.couleur)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickDebut() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureDebut,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
            ColorScheme.light(primary: widget.couleur)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _heureDebut = picked);
  }

  Future<void> _pickFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureFin,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
            ColorScheme.light(primary: widget.couleur)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _heureFin = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Nouvelle session',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.couleur)),
            const SizedBox(height: 20),

            // Titre
            TextField(
              controller: _titreCtrl,
              decoration: InputDecoration(
                labelText: 'Titre de la session',
                prefixIcon:
                const Icon(Icons.event_note_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: widget.couleur, width: 2)),
              ),
            ),
            const SizedBox(height: 14),

            // Formation associée
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)),
              child: _loadingFormations
                  ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))))
                  : _formations.isEmpty
                  ? Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12),
                  child: Row(children: [
                    Icon(Icons.school_outlined,
                        color: widget.couleur, size: 20),
                    const SizedBox(width: 8),
                    Text('Aucune formation disponible',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14)),
                  ]))
                  : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Row(children: [
                    Icon(Icons.school_outlined,
                        color: widget.couleur, size: 20),
                    const SizedBox(width: 8),
                    Text('Associer à une formation',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14)),
                  ]),
                  value: _formationId,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: widget.couleur),
                  onChanged: (id) {
                    if (id == null) return;
                    final f = _formations.firstWhere(
                            (f) => f['id'] == id);
                    setState(() {
                      _formationId = id;
                      _formationTitre =
                      f['titre'] as String;
                    });
                  },
                  items: _formations.map((f) {
                    return DropdownMenuItem<String>(
                      value: f['id'] as String,
                      child: Text(f['titre'] as String,
                          style: const TextStyle(
                              fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Date
            _PickerRow(
              icone: Icons.calendar_today_outlined,
              label: 'Date',
              valeur:
              '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
              couleur: widget.couleur,
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),

            // Heures
            Row(children: [
              Expanded(
                  child: _PickerRow(
                      icone: Icons.schedule_outlined,
                      label: 'Heure début',
                      valeur: _fmt(_heureDebut),
                      couleur: widget.couleur,
                      onTap: _pickDebut)),
              const SizedBox(width: 10),
              Expanded(
                  child: _PickerRow(
                      icone: Icons.schedule_outlined,
                      label: 'Heure fin',
                      valeur: _fmt(_heureFin),
                      couleur: widget.couleur,
                      onTap: _pickFin)),
            ]),
            const SizedBox(height: 14),

            // Participants max
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.group_outlined,
                    color: widget.couleur, size: 20),
                const SizedBox(width: 10),
                const Text('Participants max',
                    style: TextStyle(fontSize: 14)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 22),
                  onPressed: _maxParticipants > 1
                      ? () => setState(() => _maxParticipants--)
                      : null,
                  color: widget.couleur,
                ),
                SizedBox(
                    width: 32,
                    child: Text('$_maxParticipants',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      size: 22),
                  onPressed: () =>
                      setState(() => _maxParticipants++),
                  color: widget.couleur,
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Bouton valider
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_titreCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Veuillez saisir un titre'),
                            backgroundColor: Colors.orange));
                    return;
                  }
                  final uid = FirebaseAuth
                      .instance.currentUser?.uid ??
                      widget.formateurUid;
                  Navigator.pop(
                      context,
                      SessionModel(
                        id: '',
                        formationId: _formationId ?? '',
                        formationTitre: _formationTitre,
                        formateurId: uid,
                        formateurNom: '',
                        date: _date,
                        heureDebut: _fmt(_heureDebut),
                        heureFin: _fmt(_heureFin),
                        participantsIds: const [],
                        statut: 'planifiee',
                        titre: _titreCtrl.text.trim(),
                        maxParticipants: _maxParticipants,
                      ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.couleur,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Ajouter cette session',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Ligne sélecteur date/heure ─────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;
  final Color couleur;
  final VoidCallback onTap;
  const _PickerRow(
      {required this.icone,
        required this.label,
        required this.valeur,
        required this.couleur,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icone, color: couleur, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500)),
                  Text(valeur,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              )),
          Icon(Icons.chevron_right,
              color: Colors.grey.shade400, size: 18),
        ]),
      ),
    );
  }
}