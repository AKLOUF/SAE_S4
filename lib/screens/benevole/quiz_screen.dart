import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizScreen extends StatefulWidget {
  final String formationId;
  final String titrFormation;

  const QuizScreen({
    super.key,
    required this.formationId,
    required this.titrFormation,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<Map<String, dynamic>> _questions = [
    {
      'enonce': 'Que signifie l\'inclusion sociale ?',
      'options': [
        'Exclure certains groupes de la société',
        'Permettre à tous de participer pleinement à la société',
        'Réserver des droits à certains citoyens',
        'Ignorer les différences culturelles',
      ],
      'reponse_correcte': 1,
    },
    {
      'enonce': 'Quel est un exemple de pratique inclusive ?',
      'options': [
        'Refuser l\'accès aux personnes handicapées',
        'Proposer des rampes d\'accès pour les fauteuils roulants',
        'Créer des espaces réservés uniquement aux valides',
        'Ignorer les besoins spécifiques',
      ],
      'reponse_correcte': 1,
    },
    {
      'enonce': 'La diversité culturelle est :',
      'options': [
        'Un obstacle au développement',
        'Une source de conflits uniquement',
        'Une richesse pour la société',
        'Un problème à résoudre',
      ],
      'reponse_correcte': 2,
    },
  ];

  int _questionActuelle = 0;
  int? _reponseSelectionnee;
  int _score = 0;
  bool _quizTermine = false;

  void _repondre(int index) {
    setState(() => _reponseSelectionnee = index);
  }

  void _questionSuivante() {
    if (_reponseSelectionnee == null) return;
    if (_reponseSelectionnee ==
        _questions[_questionActuelle]['reponse_correcte']) {
      _score++;
    }
    if (_questionActuelle < _questions.length - 1) {
      setState(() {
        _questionActuelle++;
        _reponseSelectionnee = null;
      });
    } else {
      setState(() => _quizTermine = true);
      _sauvegarderResultat();
    }
  }

  Future<void> _sauvegarderResultat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    double pourcentage = (_score / _questions.length) * 100;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quiz_results')
        .add({
      'titre': widget.titrFormation,
      'score': pourcentage,
      'date': FieldValue.serverTimestamp(),
    });
    if (pourcentage >= 70) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('badges')
          .add({
        'formation_id': widget.formationId,
        'titre': widget.titrFormation,
        'date_obtention': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizTermine) {
      double pourcentage = (_score / _questions.length) * 100;
      bool reussi = pourcentage >= 70;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultat'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  reussi ? Icons.emoji_events : Icons.refresh,
                  size: 80,
                  color: reussi ? Colors.amber : Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  reussi ? 'Félicitations !' : 'Continuez vos efforts !',
                  style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Score : $_score / ${_questions.length}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  '${pourcentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: reussi ? Colors.teal : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                if (reussi)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('Badge obtenu !',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retour aux formations'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_questionActuelle];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titrFormation),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_questionActuelle + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              color: Colors.teal,
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${_questionActuelle + 1} / ${_questions.length}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              question['enonce'],
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              (question['options'] as List).length,
              (i) => GestureDetector(
                onTap: () => _repondre(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _reponseSelectionnee == i
                        ? Colors.teal.shade100
                        : Colors.white,
                    border: Border.all(
                      color: _reponseSelectionnee == i
                          ? Colors.teal
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question['options'][i],
                    style: TextStyle(
                      fontSize: 16,
                      color: _reponseSelectionnee == i
                          ? Colors.teal.shade800
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _reponseSelectionnee != null
                    ? _questionSuivante
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _questionActuelle < _questions.length - 1
                      ? 'Question suivante'
                      : 'Terminer le quiz',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}