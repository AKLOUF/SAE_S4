import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class FormationDetailScreen extends StatelessWidget {
  final String formationId;
  final String titre;
  final String description;
  final String thematique;

  const FormationDetailScreen({
    super.key,
    required this.formationId,
    required this.titre,
    required this.description,
    required this.thematique,
  });

  Color _thematiqueColor() {
    switch (thematique.toLowerCase()) {
      case 'inclusion': return const Color(0xFF7C3AED);
      case 'environnement': return const Color(0xFF059669);
      case 'egalite': return const Color(0xFFDC2626);
      case 'tolerance': return const Color(0xFFD97706);
      case 'citoyennete': return const Color(0xFF2563EB);
      default: return const Color(0xFF00796B);
    }
  }

  IconData _thematiqueIcon() {
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
    final color = _thematiqueColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        slivers: [
          // Header avec dégradé
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_thematiqueIcon(),
                                color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(thematique,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(titre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Description
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                              color: color, size: 20),
                            const SizedBox(width: 8),
                            const Text('À propos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A1A2E))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.6)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Modules
                  const Row(
                    children: [
                      SizedBox(width: 4),
                      Text('Contenu de la formation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _ModuleCard(
                    numero: 1,
                    titre: 'Introduction',
                    description:
                      'Présentation des concepts fondamentaux de la thématique.',
                    color: color,
                  ),
                  const SizedBox(height: 10),
                  _ModuleCard(
                    numero: 2,
                    titre: 'Approfondissement',
                    description:
                      'Exploration des enjeux actuels et des solutions possibles.',
                    color: color,
                  ),
                  const SizedBox(height: 10),
                  _ModuleCard(
                    numero: 3,
                    titre: 'Mise en pratique',
                    description:
                      'Exercices et cas concrets pour ancrer les apprentissages.',
                    color: color,
                  ),

                  const SizedBox(height: 12),

                  // Info quiz
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.quiz_outlined, color: color, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quiz de validation',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 14)),
                              const Text(
                                '3 questions • Score minimum 70% pour obtenir le badge',
                                style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton quiz
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            formationId: formationId,
                            titrFormation: titre,
                          ))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 22),
                          SizedBox(width: 8),
                          Text('Commencer le quiz',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final int numero;
  final String titre;
  final String description;
  final Color color;

  const _ModuleCard({
    required this.numero,
    required this.titre,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text('$numero',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Module $numero : $titre',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline,
            color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }
}