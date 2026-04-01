import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/certification_service.dart';

class CertificationsAdminScreen extends StatefulWidget {
  const CertificationsAdminScreen({super.key});

  @override
  State<CertificationsAdminScreen> createState() =>
      _CertificationsAdminScreenState();
}

class _CertificationsAdminScreenState
    extends State<CertificationsAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
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
                    padding: EdgeInsets.fromLTRB(72, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Administration 🏆',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Certifications',
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
          ),
        ],
        body: Column(
          children: [
            // ── Onglets ──────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF00796B),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF00796B),
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.hourglass_top_rounded, size: 18),
                    text: 'En attente',
                  ),
                  Tab(
                    icon: Icon(Icons.history_rounded, size: 18),
                    text: 'Historique',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _OngletEnAttente(),
                  _OngletHistorique(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Onglet demandes en attente ─────────────────────────────────────────────────
class _OngletEnAttente extends StatelessWidget {
  const _OngletEnAttente();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: CertificationService().getDemandesEnAttente(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Aucune demande en attente',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('Toutes les demandes ont été traitées',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _DemandeCertifCard(
              data: data,
              showActions: true,
            );
          },
        );
      },
    );
  }
}

// ── Onglet historique ─────────────────────────────────────────────────────────
class _OngletHistorique extends StatelessWidget {
  const _OngletHistorique();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: CertificationService().getToutesLesDemandes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00796B)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Aucune demande',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final statut = data['statut'] as String? ?? '';
            return _DemandeCertifCard(
              data: data,
              showActions: statut == 'en_attente',
            );
          },
        );
      },
    );
  }
}

// ── Card demande de certification ─────────────────────────────────────────────
class _DemandeCertifCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool showActions;

  const _DemandeCertifCard({
    required this.data,
    required this.showActions,
  });

  @override
  State<_DemandeCertifCard> createState() => _DemandeCertifCardState();
}

class _DemandeCertifCardState extends State<_DemandeCertifCard> {
  bool _isLoading = false;

  static const Map<String, Map<String, dynamic>> _thematiques = {
    'inclusion': {'couleur': Color(0xFF7C3AED), 'icone': Icons.people, 'label': 'Inclusion'},
    'environnement': {'couleur': Color(0xFF059669), 'icone': Icons.eco, 'label': 'Environnement'},
    'egalite': {'couleur': Color(0xFFDC2626), 'icone': Icons.balance, 'label': 'Égalité'},
    'tolerance': {'couleur': Color(0xFFD97706), 'icone': Icons.handshake, 'label': 'Tolérance'},
    'citoyennete': {'couleur': Color(0xFF2563EB), 'icone': Icons.account_balance, 'label': 'Citoyenneté'},
  };

  Future<void> _valider() async {
    setState(() => _isLoading = true);
    try {
      await CertificationService().validerCertification(
        benevoleId: widget.data['benevoleId'] as String,
        thematique: widget.data['thematique'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certification validée ✓'),
            backgroundColor: Color(0xFF00796B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refuser() async {
    final motifCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Refuser la certification',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voulez-vous refuser la certification de ${widget.data['nomBenevole']} ?',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: motifCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Motif du refus (optionnel)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00796B)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await CertificationService().refuserCertification(
        benevoleId: widget.data['benevoleId'] as String,
        thematique: widget.data['thematique'] as String,
        motif: motifCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thematique = widget.data['thematique'] as String? ?? '';
    final nomBenevole = widget.data['nomBenevole'] as String? ?? 'Bénévole';
    final emailBenevole = widget.data['emailBenevole'] as String? ?? '';
    final statut = widget.data['statut'] as String? ?? 'en_attente';
    final dateDemande = widget.data['dateDemande'];

    final thInfo = _thematiques[thematique] ?? _thematiques['inclusion']!;
    final couleur = thInfo['couleur'] as Color;
    final icone = thInfo['icone'] as IconData;
    final themLabel = thInfo['label'] as String;

    // Config statut
    final statutConfig = {
      'en_attente': {
        'label': 'En attente',
        'couleur': const Color(0xFF2563EB),
        'fond': const Color(0xFFEFF6FF),
        'icone': Icons.hourglass_top_rounded,
      },
      'validee': {
        'label': 'Validée',
        'couleur': const Color(0xFF00796B),
        'fond': const Color(0xFFE0F2EF),
        'icone': Icons.check_circle_outline,
      },
      'refusee': {
        'label': 'Refusée',
        'couleur': const Color(0xFFDC2626),
        'fond': const Color(0xFFFEF2F2),
        'icone': Icons.cancel_outlined,
      },
    };
    final sc = statutConfig[statut] ?? statutConfig['en_attente']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ────────────────────────────────────
            Row(
              children: [
                // Avatar bénévole
                CircleAvatar(
                  radius: 22,
                  backgroundColor: couleur.withValues(alpha: 0.15),
                  child: Text(
                    nomBenevole.isNotEmpty
                        ? nomBenevole[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: couleur,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomBenevole,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E))),
                      Text(emailBenevole,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                // Badge statut
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (sc['fond'] as Color),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (sc['couleur'] as Color).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sc['icone'] as IconData,
                          size: 13, color: sc['couleur'] as Color),
                      const SizedBox(width: 4),
                      Text(sc['label'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: sc['couleur'] as Color)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Thématique demandée ────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: couleur.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(icone, color: couleur, size: 18),
                  const SizedBox(width: 8),
                  Text('Certification $themLabel',
                      style: TextStyle(
                          color: couleur,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),

            // ── Date de demande ────────────────────────────
            if (dateDemande != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                        () {
                      try {
                        final date =
                        (dateDemande as dynamic).toDate() as DateTime;
                        return 'Demandée le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                      } catch (_) {
                        return 'Date inconnue';
                      }
                    }(),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],

            // ── Boutons valider / refuser ──────────────────
            if (widget.showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _refuser,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _valider,
                      icon: _isLoading
                          ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}