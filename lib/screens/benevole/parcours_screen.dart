import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/certification_service.dart';

class ParcoursScreen extends StatelessWidget {
  const ParcoursScreen({super.key});

  static const List<Map<String, dynamic>> thematiques = [
    {'valeur': 'inclusion', 'label': 'Inclusion',
      'icone': Icons.people, 'couleur': Color(0xFF7C3AED)},
    {'valeur': 'environnement', 'label': 'Environnement',
      'icone': Icons.eco, 'couleur': Color(0xFF059669)},
    {'valeur': 'egalite', 'label': 'Égalité',
      'icone': Icons.balance, 'couleur': Color(0xFFDC2626)},
    {'valeur': 'tolerance', 'label': 'Tolérance',
      'icone': Icons.handshake, 'couleur': Color(0xFFD97706)},
    {'valeur': 'citoyennete', 'label': 'Citoyenneté',
      'icone': Icons.account_balance, 'couleur': Color(0xFF2563EB)},
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF00796B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00796B), Color(0xFF004D40)],
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(72, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Mon parcours',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Certifications',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final theme = thematiques[i];
                  return _ThematiqueCard(
                    uid: uid,
                    user: user,
                    thematique: theme['valeur'] as String,
                    label: theme['label'] as String,
                    icone: theme['icone'] as IconData,
                    couleur: theme['couleur'] as Color,
                  );
                },
                childCount: thematiques.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card par thématique ───────────────────────────────────────────────────────
class _ThematiqueCard extends StatefulWidget {
  final String uid;
  final User? user;
  final String thematique;
  final String label;
  final IconData icone;
  final Color couleur;

  const _ThematiqueCard({
    required this.uid,
    required this.user,
    required this.thematique,
    required this.label,
    required this.icone,
    required this.couleur,
  });

  @override
  State<_ThematiqueCard> createState() => _ThematiqueCardState();
}

class _ThematiqueCardState extends State<_ThematiqueCard> {
  bool _isSubmitting = false;

  Future<void> _demanderCertification() async {
    setState(() => _isSubmitting = true);
    try {
      // Récupère les infos du bénévole
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final nom = userData['nom'] ?? widget.user?.displayName ?? 'Bénévole';
      final email = userData['email'] ?? widget.user?.email ?? '';

      await CertificationService().demanderCertification(
        uid: widget.uid,
        thematique: widget.thematique,
        nomBenevole: nom,
        emailBenevole: email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée ! En attente de validation admin.'),
            backgroundColor: Color(0xFF00796B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: CertificationService().getProgression(
            uid: widget.uid, thematique: widget.thematique),
        builder: (context, snap) {
          final progression = snap.data;
          final total = progression?['total'] ?? 0;
          final reussis = progression?['reussis'] ?? 0;
          final pct = (progression?['pourcentage'] ?? 0.0) as double;
          final eligible = reussis == total && total > 0;
          final formations = progression?['formations']
          as List<Map<String, dynamic>>? ??
              [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: eligible ? Colors.amber : widget.couleur,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        eligible ? Icons.workspace_premium : widget.icone,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A2E))),
                          Text(
                            eligible
                                ? '🏆 Toutes les formations réussies !'
                                : '$reussis / $total formations réussies',
                            style: TextStyle(
                              color: eligible
                                  ? Colors.amber.shade700
                                  : Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: eligible
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Barre de progression ──────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: total > 0 ? pct / 100 : 0,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(
                        eligible ? Colors.amber : widget.couleur),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${pct.toStringAsFixed(0)}% complété',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12),
                ),

                // ── Liste des formations ──────────────────────
                if (formations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ...formations.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          f['reussi']
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: f['reussi']
                              ? widget.couleur
                              : Colors.grey.shade300,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f['titre'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: f['reussi']
                                  ? const Color(0xFF1A1A2E)
                                  : Colors.grey.shade500,
                              fontWeight: f['reussi']
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (f['reussi'])
                          const Text('✅',
                              style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  )),
                ],

                // ── Bouton / statut certification ─────────────
                if (eligible) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  StreamBuilder<DocumentSnapshot>(
                    stream: CertificationService().getCertificationStream(
                      uid: widget.uid,
                      thematique: widget.thematique,
                    ),
                    builder: (context, certifSnap) {
                      final data = certifSnap.data?.data()
                      as Map<String, dynamic>?;
                      final statut = data?['statut'] as String?;

                      if (statut == 'validee') {
                        return _StatutBadge(
                          icone: Icons.workspace_premium,
                          label: 'Certification OpenMinds obtenue ✓',
                          couleur: Colors.amber,
                          fond: Colors.amber.shade50,
                        );
                      }

                      if (statut == 'en_attente') {
                        return _StatutBadge(
                          icone: Icons.hourglass_top_rounded,
                          label: 'En attente de validation admin',
                          couleur: const Color(0xFF2563EB),
                          fond: const Color(0xFFEFF6FF),
                        );
                      }

                      if (statut == 'refusee') {
                        final motif = data?['motifRefus'] as String?;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatutBadge(
                              icone: Icons.cancel_outlined,
                              label: 'Demande refusée',
                              couleur: const Color(0xFFDC2626),
                              fond: const Color(0xFFFEF2F2),
                            ),
                            if (motif != null && motif.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Motif : $motif',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                            const SizedBox(height: 10),
                            // Peut re-soumettre après refus
                            _BoutonDemande(
                              label: 'Soumettre à nouveau',
                              couleur: widget.couleur,
                              isLoading: _isSubmitting,
                              onTap: _demanderCertification,
                            ),
                          ],
                        );
                      }

                      // Pas encore de demande → bouton soumettre
                      return _BoutonDemande(
                        label: 'Demander la certification',
                        couleur: widget.couleur,
                        isLoading: _isSubmitting,
                        onTap: _demanderCertification,
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Badge statut ──────────────────────────────────────────────────────────────
class _StatutBadge extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color couleur;
  final Color fond;

  const _StatutBadge({
    required this.icone,
    required this.label,
    required this.couleur,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: couleur,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bouton demande ────────────────────────────────────────────────────────────
class _BoutonDemande extends StatelessWidget {
  final String label;
  final Color couleur;
  final bool isLoading;
  final VoidCallback onTap;

  const _BoutonDemande({
    required this.label,
    required this.couleur,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.workspace_premium_outlined, size: 18),
        label: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: couleur,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}