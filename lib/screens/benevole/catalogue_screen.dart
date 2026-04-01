import 'package:flutter/material.dart';
import 'package:openminds/screens/benevole/parcours_screen.dart';
import 'package:openminds/screens/benevole/sessions_benevole_screen.dart';
import '../../services/auth_service.dart';
import '../../services/formation_service.dart';
import '../../models/formation_model.dart';
import 'formation_detail_screen.dart';
import 'dashboard_screen.dart';
import '../benevole/login_screen.dart';

class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key});

  Color _getCategoryColor(String category) {
    // Normalisation : minuscules + suppression des accents
    final c = _normalize(category);
    switch (c) {
      case 'inclusion':
        return const Color(0xFF7C3AED); // Violet
      case 'environnement':
        return const Color(0xFF059669); // Vert
      case 'egalite':
        return const Color(0xFFDC2626); // Rouge
      case 'tolerance':
        return const Color(0xFFD97706); // Orange
      case 'citoyennete':
        return const Color(0xFF2563EB); // Bleu
      default:
        return const Color(0xFF00796B); // Teal
    }
  }

  IconData _getCategoryIcon(String category) {
    final c = _normalize(category);
    switch (c) {
      case 'inclusion':      return Icons.people;
      case 'environnement':  return Icons.eco;
      case 'egalite':        return Icons.balance;
      case 'tolerance':      return Icons.handshake;
      case 'citoyennete':    return Icons.account_balance;
      default:               return Icons.school;
    }
  }

  /// Supprime les accents et met en minuscules pour un match robuste
  String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final formationService = FormationService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        slivers: [
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
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Bonjour 👋',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Formations disponibles',
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
                icon: const Icon(Icons.event_available, color: Colors.white),
                tooltip: 'Mes sessions',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SessionsBenevoleScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DashboardScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
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
              IconButton(
                icon: const Icon(Icons.workspace_premium,
                    color: Colors.white),
                tooltip: 'Mes certifications',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ParcoursScreen())),
              ),
            ],
          ),

          StreamBuilder<List<FormationModel>>(
            stream: formationService.getCatalogue(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00796B)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Erreur : ${snapshot.error}'),
                  ),
                );
              }

              final formations = snapshot.data ?? [];

              if (formations.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 16),
                        Text('Aucune formation disponible',
                            style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final formation = formations[i];
                      final String categoryName =
                      formation.categories.isNotEmpty
                          ? formation.categories.first
                          : 'inclusion';

                      final color = _getCategoryColor(categoryName);
                      final icon = _getCategoryIcon(categoryName);

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormationDetailScreen(
                                formation: formation),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // En-tête coloré
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
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
                                          Text(
                                            formation.titre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                  alpha: 0.2),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                            ),
                                            child: Text(
                                              categoryName,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                                child: Text(
                                  formation.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
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