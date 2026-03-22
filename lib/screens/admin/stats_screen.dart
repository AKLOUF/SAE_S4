import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../benevole/login_screen.dart';
import 'create_formation_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
                        const Text('Espace administrateur',
                          style: TextStyle(
                            color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text('Tableau de bord',
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Formations').snapshots(),
                          builder: (context, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            return _StatCard(
                              titre: 'Formations',
                              valeur: '$count',
                              icone: Icons.school_outlined,
                              couleur: const Color(0xFF00796B),
                              sousTitre: 'disponibles',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'benevole')
                              .snapshots(),
                          builder: (context, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            return _StatCard(
                              titre: 'Bénévoles',
                              valeur: '$count',
                              icone: Icons.people_outline,
                              couleur: const Color(0xFF2563EB),
                              sousTitre: 'inscrits',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('sessions').snapshots(),
                          builder: (context, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            return _StatCard(
                              titre: 'Sessions',
                              valeur: '$count',
                              icone: Icons.event_outlined,
                              couleur: const Color(0xFFD97706),
                              sousTitre: 'créées',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'formateur')
                              .snapshots(),
                          builder: (context, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            return _StatCard(
                              titre: 'Formateurs',
                              valeur: '$count',
                              icone: Icons.person_outline,
                              couleur: const Color(0xFF7C3AED),
                              sousTitre: 'actifs',
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Section formations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4, height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00796B),
                              borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 10),
                          const Text('Formations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Formations').snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00796B)));
                      }
                      if (snap.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200)),
                          child: const Center(
                            child: Text('Aucune formation créée',
                              style: TextStyle(color: Colors.grey))),
                        );
                      }
                      final formations = snap.data!.docs;
                      return Column(
                        children: formations.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final thematique = data['thematique'] ?? '';
                          final color = _thematiqueColor(thematique);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius:
                                      BorderRadius.circular(12)),
                                  child: Icon(
                                    _thematiqueIcon(thematique),
                                    color: color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                    children: [
                                      Text(data['titre'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1A1A2E))),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius:
                                            BorderRadius.circular(20)),
                                        child: Text(thematique,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontWeight:
                                              FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Colors.grey.shade400),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle formation',
          style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(
            builder: (_) => const CreateFormationScreen())),
      ),
    );
  }

  Color _thematiqueColor(String thematique) {
    switch (thematique.toLowerCase()) {
      case 'inclusion': return const Color(0xFF7C3AED);
      case 'environnement': return const Color(0xFF059669);
      case 'egalite': return const Color(0xFFDC2626);
      case 'tolerance': return const Color(0xFFD97706);
      case 'citoyennete': return const Color(0xFF2563EB);
      default: return const Color(0xFF00796B);
    }
  }

  IconData _thematiqueIcon(String thematique) {
    switch (thematique.toLowerCase()) {
      case 'inclusion': return Icons.people;
      case 'environnement': return Icons.eco;
      case 'egalite': return Icons.balance;
      case 'tolerance': return Icons.handshake;
      case 'citoyennete': return Icons.account_balance;
      default: return Icons.school;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;
  final String sousTitre;

  const _StatCard({
    required this.titre,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: couleur, size: 20),
          ),
          const SizedBox(height: 12),
          Text(valeur,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: couleur)),
          const SizedBox(height: 2),
          Text(titre,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1A1A2E))),
          Text(sousTitre,
            style: TextStyle(
              fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}