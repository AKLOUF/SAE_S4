import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/certification_service.dart';

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
  String? _certificationObtenue; // ← NOUVEAU
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

  // ── Sauvegarde + vérification certification ──────────────────────
  Future<void> _sauvegarderResultat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final double pourcentage = (_score / _questions.length) * 100;
    final batch = FirebaseFirestore.instance.batch();

    // 1. Sauvegarde le résultat du quiz
    final resultRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('quiz_results')
        .doc();

    batch.set(resultRef, {
      'formation_id': widget.formationId,
      'titre': widget.titrFormation,
      'score': pourcentage,
      'date': FieldValue.serverTimestamp(),
    });

    // 2. Badge si score >= 70%
    if (pourcentage >= 70) {
      final badgeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('badges')
          .doc(widget.formationId);

      batch.set(badgeRef, {
        'formation_id': widget.formationId,
        'titre': widget.titrFormation,
        'date_obtention': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // 3. Vérifie si certification débloquée
    if (pourcentage >= 70) {
      try {
        final formationDoc = await FirebaseFirestore.instance
            .collection('Formations')
            .doc(widget.formationId)
            .get();

        if (formationDoc.exists) {
          final thematique =
              formationDoc.data()?['thematique'] ?? 'inclusion';

          final certifService = CertificationService();
          final certifObtenue =
          await certifService.verifierCertification(
            uid: user.uid,
            thematique: thematique,
          );

          if (certifObtenue && mounted) {
            setState(() => _certificationObtenue = thematique);
          }
        }
      } catch (e) {
        debugPrint('Erreur vérification certification : $e');
      }
    }
  }

  // ── Couleurs des options ──────────────────────────────────────────
  Color _optionColor(int index) {
    if (!_reponseValidee) {
      return _reponseSelectionnee == index
          ? const Color(0xFF00796B).withValues(alpha: 0.1)
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

  // ── Build principal ───────────────────────────────────────────────
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
              color: Colors.white.withValues(alpha: 0.2),
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
          // Header progression
          Container(
            color: const Color(0xFF00796B),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Question ${_questionActuelle + 1} / ${_questions.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    Text('Score: $_score',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                    Colors.white.withValues(alpha: 0.3),
                    valueColor:
                    const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
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
                    Text(question['enonce'],
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            height: 1.4)),
                    const SizedBox(height: 24),
                    ...List.generate(
                      (question['options'] as List).length,
                          (i) => _buildOption(i, question['options'][i]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _reponseValidee
                      ? (_questionActuelle < _questions.length - 1
                      ? 'Suivant'
                      : 'Terminer')
                      : 'Valider',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int i, String texte) {
    return GestureDetector(
      onTap: () => _repondre(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _optionColor(i),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _optionBorderColor(i), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _reponseSelectionnee == i
                    ? const Color(0xFF00796B)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(String.fromCharCode(65 + i),
                    style: TextStyle(
                        color: _reponseSelectionnee == i
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(texte,
                    style: const TextStyle(fontSize: 16))),
            if (_optionTrailing(i) != null) _optionTrailing(i)!,
          ],
        ),
      ),
    );
  }

  // ── Écran résultat ────────────────────────────────────────────────
  Widget _buildResultat() {
    final double pourcentage = (_score / _questions.length) * 100;
    final bool reussi = pourcentage >= 70;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ── Bannière certification si obtenue ─────────────
              if (_certificationObtenue != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium,
                          color: Colors.white, size: 64),
                      const SizedBox(height: 12),
                      const Text(
                        '🎉 Certification obtenue !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Parcours ${_certificationObtenue![0].toUpperCase()}${_certificationObtenue!.substring(1)} complété !',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🏆 Badge OpenMinds débloqué !',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ── Résultat du quiz ──────────────────────────────
              Icon(
                reussi
                    ? Icons.stars
                    : Icons.sentiment_dissatisfied,
                size: 80,
                color: reussi ? Colors.amber : Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                reussi ? 'Félicitations !' : 'Dommage...',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Score : ${pourcentage.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),

              // ── Message selon résultat ────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: reussi
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reussi
                      ? '✅ Quiz réussi ! Badge obtenu.'
                      : '❌ Score insuffisant. Il faut 70% minimum.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: reussi
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Bouton retour ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Retour aux formations',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              // ── Bouton voir certifications si obtenue ─────────
              if (_certificationObtenue != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigation vers ParcoursScreen
                      Navigator.pushNamed(
                          context, '/benevole/parcours');
                    },
                    icon: const Icon(Icons.workspace_premium,
                        color: Color(0xFF00796B)),
                    label: const Text(
                      'Voir mes certifications',
                      style: TextStyle(
                          color: Color(0xFF00796B),
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF00796B), width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}