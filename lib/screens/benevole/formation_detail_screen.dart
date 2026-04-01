import 'package:flutter/material.dart';
import '../../models/formation_model.dart';
import 'quiz_screen.dart';

class FormationDetailScreen extends StatelessWidget {
  final FormationModel formation;

  const FormationDetailScreen({
    super.key,
    required this.formation,
  });

  String get _mainCategory => formation.categories.isNotEmpty
      ? formation.categories.first
      : 'Inclusion';

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'inclusion': return const Color(0xFF7C3AED);
      case 'environnement': return const Color(0xFF059669);
      case 'egalite': return const Color(0xFFDC2626);
      case 'tolerance': return const Color(0xFFD97706);
      case 'citoyennete': return const Color(0xFF2563EB);
      default: return const Color(0xFF00796B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
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
    final color = _getCategoryColor(_mainCategory);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      // --- MODIFICATION ICI : On place le bouton en bas de l'écran ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30), // Marges pour décoller du bord
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F1F1), width: 1)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  formationId: formation.id,
                  titrFormation: formation.titre,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Commencer le quiz',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getCategoryIcon(_mainCategory), color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(_mainCategory,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(formation.titre,
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
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: color, size: 20),
                            const SizedBox(width: 8),
                            const Text('À propos',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A1A2E))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(formation.description,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Contenu de la formation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 14),
                  _ModuleTile(numero: 1, titre: 'Introduction', color: color),
                  _ModuleTile(numero: 2, titre: 'Enjeux principaux', color: color),
                  _ModuleTile(numero: 3, titre: 'Cas pratiques', color: color),
                  const SizedBox(height: 100), // Espace supplémentaire pour ne pas cacher le contenu par le bouton
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... garder le reste du code (_ModuleTile) identique ...
class _ModuleTile extends StatelessWidget {
  final int numero;
  final String titre;
  final Color color;

  const _ModuleTile({required this.numero, required this.titre, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text('$numero', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(titre, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
          const Spacer(),
          Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}