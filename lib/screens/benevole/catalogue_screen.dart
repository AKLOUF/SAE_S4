import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../benevole/login_screen.dart';
import 'formation_detail_screen.dart';
import 'dashboard_screen.dart';

class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key});

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
                        const Text('Bonjour 👋',
                          style: TextStyle(
                            color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text('Formations disponibles',
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
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => const DashboardScreen())),
              ),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Formations').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
                    color: Color(0xFF00796B))));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                          size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucune formation disponible',
                          style: TextStyle(
                            color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }
              final formations = snapshot.data!.docs;
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final data =
                          formations[i].data() as Map<String, dynamic>;
                      final thematique = data['thematique'] ?? '';
                      final color = _thematiqueColor(thematique);
                      final icon = _thematiqueIcon(thematique);

                      return GestureDetector(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                            builder: (_) => FormationDetailScreen(
                              formationId: formations[i].id,
                              titre: data['titre'] ?? '',
                              description: data['description'] ?? '',
                              thematique: thematique,
                            ))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header coloré
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.08),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius:
                                          BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon,
                                        color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                        children: [
                                          Text(data['titre'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1A1A2E))),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              borderRadius:
                                                BorderRadius.circular(20),
                                            ),
                                            child: Text(thematique,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios,
                                      color: color, size: 16),
                                  ],
                                ),
                              ),
                              // Description
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(data['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    height: 1.5)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: formations.length,
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