import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../benevole/login_screen.dart';

class ParticipantsScreen extends StatelessWidget {
  const ParticipantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text('Espace formateur',
                          style: TextStyle(
                            color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text('Mes sessions',
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
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen()));
                  }
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: Color(0xFF00796B)),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00796B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.group_outlined,
                              size: 40, color: Color(0xFF00796B)),
                          ),
                          const SizedBox(height: 16),
                          const Text('Aucune session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 8),
                          Text('Appuyez sur + pour créer votre première session',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }

                final sessions = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final data =
                        sessions[i].data() as Map<String, dynamic>;
                    return _SessionCard(
                      sessionId: sessions[i].id,
                      titre: data['titre'] ?? 'Session',
                      formation: data['formation'] ?? '',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle session',
          style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _afficherDialogSession(context),
      ),
    );
  }

  void _afficherDialogSession(BuildContext context) {
    final titreCtrl = TextEditingController();
    final formationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_circle_outline,
                color: Color(0xFF00796B), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Nouvelle session',
              style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
              controller: titreCtrl,
              label: 'Titre de la session',
              icon: Icons.title,
            ),
            const SizedBox(height: 14),
            _buildDialogField(
              controller: formationCtrl,
              label: 'Formation associée',
              icon: Icons.school_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
              style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (titreCtrl.text.isEmpty ||
                  formationCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('sessions').add({
                'titre': titreCtrl.text.trim(),
                'formation': formationCtrl.text.trim(),
                'date': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00796B), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00796B), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(
          color: Colors.grey.shade600, fontSize: 14),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String sessionId;
  final String titre;
  final String formation;

  const _SessionCard({
    required this.sessionId,
    required this.titre,
    required this.formation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          leading: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00796B), Color(0xFF004D40)]),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.group, color: Colors.white, size: 22),
          ),
          title: Text(titre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1A2E))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                const Icon(Icons.school_outlined,
                  size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(formation,
                  style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _afficherDialogParticipant(
                  context, sessionId),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.person_add_outlined,
                    color: Color(0xFF00796B), size: 18),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down,
                color: Colors.grey),
            ],
          ),
          children: [
            _ParticipantsList(sessionId: sessionId),
          ],
        ),
      ),
    );
  }

  void _afficherDialogParticipant(
      BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (ctx) => _DialogAjoutParticipant(sessionId: sessionId),
    );
  }
}

class _DialogAjoutParticipant extends StatefulWidget {
  final String sessionId;
  const _DialogAjoutParticipant({required this.sessionId});

  @override
  State<_DialogAjoutParticipant> createState() =>
      _DialogAjoutParticipantState();
}

class _DialogAjoutParticipantState
    extends State<_DialogAjoutParticipant> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00796B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_search,
              color: Color(0xFF00796B), size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Ajouter un bénévole',
            style: TextStyle(fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou email...',
                prefixIcon: const Icon(Icons.search,
                  color: Color(0xFF00796B), size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF00796B), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (v) =>
                  setState(() => _recherche = v.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'benevole')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00796B)));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                            size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('Aucun bénévole inscrit',
                            style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final benevoles = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nom =
                        (data['nom'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    return _recherche.isEmpty ||
                        nom.contains(_recherche) ||
                        email.contains(_recherche);
                  }).toList();

                  if (benevoles.isEmpty) {
                    return const Center(
                      child: Text('Aucun résultat',
                        style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    itemCount: benevoles.length,
                    itemBuilder: (context, i) {
                      final data =
                          benevoles[i].data() as Map<String, dynamic>;
                      final uid = benevoles[i].id;
                      final nom = data['nom'] ?? 'Bénévole';
                      final email = data['email'] ?? '';

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('sessions')
                            .doc(widget.sessionId)
                            .collection('inscrits')
                            .doc(uid)
                            .get(),
                        builder: (context, snapInscrit) {
                          final dejaInscrit =
                              snapInscrit.data?.exists ?? false;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: dejaInscrit
                                  ? Colors.grey.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: dejaInscrit
                                    ? Colors.grey.shade200
                                    : const Color(0xFF00796B)
                                        .withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: dejaInscrit
                                      ? Colors.grey.shade300
                                      : const Color(0xFF00796B),
                                  child: Text(
                                    nom[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                    children: [
                                      Text(nom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                      Text(email,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11),
                                        overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                dejaInscrit
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius:
                                          BorderRadius.circular(8)),
                                      child: const Text('Inscrit',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey)),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                          const Color(0xFF00796B),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                            BorderRadius.circular(8)),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('sessions')
                                            .doc(widget.sessionId)
                                            .collection('inscrits')
                                            .doc(uid)
                                            .set({
                                          'nom': nom,
                                          'email': email,
                                          'uid': uid,
                                          'present': false,
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                              '$nom ajouté !'),
                                            backgroundColor:
                                              const Color(0xFF00796B),
                                          ));
                                        }
                                      },
                                      child: const Text('Ajouter',
                                        style: TextStyle(fontSize: 12)),
                                    ),
                              ],
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer',
            style: TextStyle(color: Color(0xFF00796B)))),
      ],
    );
  }
}

class _ParticipantsList extends StatelessWidget {
  final String sessionId;
  const _ParticipantsList({required this.sessionId});

  Future<void> _validerPresence(
      BuildContext context, String userId, String sessionId) async {
    final session = await FirebaseFirestore.instance
        .collection('sessions').doc(sessionId).get();
    final formation = session.data()?['formation'] ?? 'Formation';

    await FirebaseFirestore.instance
        .collection('sessions').doc(sessionId)
        .collection('inscrits').doc(userId)
        .update({'present': true});

    await FirebaseFirestore.instance
        .collection('users').doc(userId)
        .collection('badges').add({
      'titre': formation,
      'date_obtention': FieldValue.serverTimestamp(),
      'type': 'participation',
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Présence validée — badge attribué !'),
          backgroundColor: Color(0xFF00796B),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions').doc(sessionId)
          .collection('inscrits').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(
              color: Color(0xFF00796B))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                    color: Colors.grey.shade400, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Aucun participant — appuyez sur + pour en ajouter',
                    style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),),
                ],
              ),
            ),
          );
        }

        final inscrits = snapshot.data!.docs;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: inscrits.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final present = data['present'] ?? false;
              final nom = data['nom'] ?? 'Participant';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: present
                      ? const Color(0xFF00796B).withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: present
                        ? const Color(0xFF00796B).withOpacity(0.3)
                        : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: present
                          ? const Color(0xFF00796B)
                          : Colors.grey.shade300,
                      child: present
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : Text(nom[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1A1A2E))),
                          Text(
                            present ? 'Présent ✓' : 'En attente de validation',
                            style: TextStyle(
                              fontSize: 12,
                              color: present
                                  ? const Color(0xFF00796B)
                                  : Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    present
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.emoji_events,
                              color: Colors.amber, size: 18),
                          )
                        : ElevatedButton(
                            onPressed: () => _validerPresence(
                              context, doc.id, sessionId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Valider',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                          ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}