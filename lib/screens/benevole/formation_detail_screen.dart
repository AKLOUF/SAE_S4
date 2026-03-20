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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titre),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(thematique,
                style: TextStyle(color: Colors.teal.shade800)),
            ),
            const SizedBox(height: 24),
            Text(titre,
              style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(description,
              style: const TextStyle(fontSize: 16, height: 1.6)),
            const SizedBox(height: 32),
            const Text('Contenu de la formation',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Module 1 : Introduction\nCe module présente les concepts fondamentaux de la thématique.\n\nModule 2 : Approfondissement\nExploration des enjeux actuels et des solutions possibles.\n\nModule 3 : Mise en pratique\nExercices et cas concrets pour ancrer les apprentissages.',
              style: TextStyle(fontSize: 15, height: 1.7)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => QuizScreen(
                    formationId: formationId,
                    titrFormation: titre,
                ))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Commencer le quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}