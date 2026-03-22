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

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {

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
  bool _reponseValidee = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(
      parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _repondre(int index) {
    if (_reponseValidee) return;
    setState(() => _reponseSelectionnee = index);
  }

  void _valider() {
    if (_reponseSelectionnee == null) return;
    setState(() => _reponseValidee = true);
    if (_reponseSelectionnee ==
        _questions[_questionActuelle]['reponse_correcte']) {
      _score++;
    }
  }

  void _questionSuivante() {
    if (_questionActuelle < _questions.length - 1) {
      _animController.reset();
      setState(() {
        _questionActuelle++;
        _reponseSelectionnee = null;
        _reponseValidee = false;
      });
      _animController.forward();
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
        .collection('users').doc(uid)
        .collection('quiz_results').add({
      'titre': widget.titrFormation,
      'score': pourcentage,
      'date': FieldValue.serverTimestamp(),
    });
    if (pourcentage >= 70) {
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('badges').add({
        'formation_id': widget.formationId,
        'titre': widget.titrFormation,
        'date_obtention': FieldValue.serverTimestamp(),
      });
    }
  }

  Color _optionColor(int index) {
    if (!_reponseValidee) {
      return _reponseSelectionnee == index
          ? const Color(0xFF00796B).withOpacity(0.1)
          : Colors.white;
    }
    if (index == _questions[_questionActuelle]['reponse_correcte']) {
      return Colors.green.shade50;
    }
    if (index == _reponseSelectionnee) return Colors.red.shade50;
    return Colors.white;
  }

  Color _optionBorderColor(int index) {
    if (!_reponseValidee) {
      return _reponseSelectionnee == index
          ? const Color(0xFF00796B)
          : Colors.grey.shade200;
    }
    if (index == _questions[_questionActuelle]['reponse_correcte']) {
      return Colors.green;
    }
    if (index == _reponseSelectionnee) return Colors.red;
    return Colors.grey.shade200;
  }

  Widget? _optionTrailing(int index) {
    if (!_reponseValidee) return null;
    if (index == _questions[_questionActuelle]['reponse_correcte']) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (index == _reponseSelectionnee) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_quizTermine) return _buildResultat();

    final question = _questions[_questionActuelle];
    final progress = (_questionActuelle + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.titrFormation,
          style: const TextStyle(fontSize: 16)),
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
      ),
      body: Column(
        children: [
          // Barre de progression
          Container(
            color: const Color(0xFF00796B),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_questionActuelle + 1} sur ${_questions.length}',
                      style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_score / ${_questions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Question
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(question['enonce'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                          height: 1.4)),
                    ),
                    const SizedBox(height: 20),

                    // Options
                    ...List.generate(
                      (question['options'] as List).length,
                      (i) => GestureDetector(
                        onTap: () => _repondre(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _optionColor(i),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _optionBorderColor(i), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: _reponseSelectionnee == i && !_reponseValidee
                                      ? const Color(0xFF00796B)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _reponseSelectionnee == i && !_reponseValidee
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(question['options'][i],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _reponseSelectionnee == i
                                        ? const Color(0xFF1A1A2E)
                                        : Colors.grey.shade700,
                                    fontWeight: _reponseSelectionnee == i
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                              ),
                              if (_optionTrailing(i) != null)
                                _optionTrailing(i)!,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton valider / suivant
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _reponseSelectionnee == null
                    ? null
                    : _reponseValidee
                        ? _questionSuivante
                        : _valider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _reponseValidee
                      ? (_questionActuelle < _questions.length - 1
                          ? 'Question suivante →'
                          : 'Voir le résultat')
                      : 'Valider ma réponse',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultat() {
    double pourcentage = (_score / _questions.length) * 100;
    bool reussi = pourcentage >= 70;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Icône résultat
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: reussi
                      ? Colors.amber.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  reussi ? Icons.emoji_events : Icons.refresh,
                  size: 50,
                  color: reussi ? Colors.amber : Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                reussi ? 'Bravo !' : 'Continuez vos efforts !',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              Text(
                reussi
                    ? 'Vous avez validé cette formation avec succès.'
                    : 'Relisez le contenu et réessayez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 15)),
              const SizedBox(height: 32),

              // Score
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${pourcentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: reussi
                            ? const Color(0xFF00796B)
                            : Colors.red.shade400)),
                    Text(
                      '$_score bonne${_score > 1 ? 's' : ''} réponse${_score > 1 ? 's' : ''} sur ${_questions.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 15)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pourcentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          reussi ? const Color(0xFF00796B) : Colors.red.shade300),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Badge obtenu
              if (reussi)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Badge obtenu !',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E))),
                            Text(widget.titrFormation,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Retour aux formations',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}