import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/session_model.dart';
import '../../services/formation_service.dart';

class CreateFormationScreen extends StatefulWidget {
  const CreateFormationScreen({super.key});

  @override
  State<CreateFormationScreen> createState() => _CreateFormationScreenState();
}

class _CreateFormationScreenState extends State<CreateFormationScreen> {
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<SessionModel> _sessions = [];
  String _thematique = 'inclusion';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _thematiques = [
    {'valeur': 'inclusion', 'label': 'Inclusion', 'icone': Icons.people, 'couleur': const Color(0xFF7C3AED)},
    {'valeur': 'environnement', 'label': 'Environnement', 'icone': Icons.eco, 'couleur': const Color(0xFF059669)},
    {'valeur': 'egalite', 'label': 'Égalité', 'icone': Icons.balance, 'couleur': const Color(0xFFDC2626)},
    {'valeur': 'tolerance', 'label': 'Tolérance', 'icone': Icons.handshake, 'couleur': const Color(0xFFD97706)},
    {'valeur': 'citoyennete', 'label': 'Citoyenneté', 'icone': Icons.account_balance, 'couleur': const Color(0xFF2563EB)},
  ];

  Color get _selectedColor {
    final t = _thematiques.firstWhere((t) => t['valeur'] == _thematique);
    return t['couleur'] as Color;
  }

  Future<void> _creer() async {
    if (_titreCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = FormationService();
      final formationId = await service.createFormation(
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        thematique: _thematique,
      );
      for (final session in _sessions) {
        final sessionComplete = SessionModel(
          id: '',
          formationId: formationId,
          formationTitre: _titreCtrl.text.trim(),
          formateurId: session.formateurId.isEmpty
              ? (FirebaseAuth.instance.currentUser?.uid ?? '')
              : session.formateurId,
          formateurNom: session.formateurNom,
          date: session.date,
          heureDebut: session.heureDebut,
          heureFin: session.heureFin,
          participantsIds: const [],
          statut: 'planifiee',
          titre: session.titre,
          maxParticipants: session.maxParticipants,
        );
        await service.addSession(sessionComplete);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formation créée avec succès !'), backgroundColor: Color(0xFF00796B)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterSession() async {
    final session = await showModalBottomSheet<SessionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSessionSheet(
        couleur: _selectedColor,
        formationTitre: _titreCtrl.text.trim(),
      ),
    );
    if (session != null) setState(() => _sessions.add(session));
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouvelle formation', style: TextStyle(fontSize: 18)),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(icone: Icons.title, label: 'Titre de la formation', couleur: _selectedColor),
            const SizedBox(height: 10),
            _buildTextField(controller: _titreCtrl, hint: 'Ex: Inclusion et diversité', icone: Icons.edit_outlined, maxLines: 1),
            const SizedBox(height: 24),

            _SectionLabel(icone: Icons.category_outlined, label: 'Thématique', couleur: _selectedColor),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
              ),
              itemCount: _thematiques.length,
              itemBuilder: (context, i) {
                final t = _thematiques[i];
                final selected = _thematique == t['valeur'];
                final color = t['couleur'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _thematique = t['valeur'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? color : Colors.grey.shade200, width: 2),
                      boxShadow: selected
                          ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t['icone'] as IconData, color: selected ? Colors.white : color, size: 24),
                        const SizedBox(height: 6),
                        Text(t['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : const Color(0xFF1A1A2E))),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            _SectionLabel(icone: Icons.description_outlined, label: 'Description', couleur: _selectedColor),
            const SizedBox(height: 10),
            _buildTextField(controller: _descCtrl, hint: 'Décrivez le contenu et les objectifs...', icone: Icons.notes_outlined, maxLines: 5),
            const SizedBox(height: 24),

            _SectionLabel(icone: Icons.event_outlined, label: 'Sessions', couleur: _selectedColor),
            const SizedBox(height: 10),

            ..._sessions.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.event, color: _selectedColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.titre.isEmpty ? 'Session ${i + 1}' : s.titre,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 3),
                          Text(
                            '${s.date.day.toString().padLeft(2,'0')}/${s.date.month.toString().padLeft(2,'0')}/${s.date.year}'
                                '${s.heureDebut.isNotEmpty ? ' · ${s.heureDebut}' : ''}'
                                '${s.heureFin.isNotEmpty ? ' → ${s.heureFin}' : ''}'
                                '${s.formateurNom.isNotEmpty ? ' · ${s.formateurNom}' : ''}'
                                ' · ${s.maxParticipants} places',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _sessions.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),

            TextButton.icon(
              onPressed: _ajouterSession,
              icon: Icon(Icons.add_circle_outline, color: _selectedColor),
              label: Text('Ajouter une session',
                  style: TextStyle(color: _selectedColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 24),

            // Aperçu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _selectedColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _selectedColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      (_thematiques.firstWhere((t) => t['valeur'] == _thematique)['icone']) as IconData,
                      color: Colors.white, size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titreCtrl.text.isEmpty ? 'Titre de la formation' : _titreCtrl.text,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14,
                              color: _titreCtrl.text.isEmpty ? Colors.grey : const Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: _selectedColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                          child: Text(_thematique,
                              style: TextStyle(color: _selectedColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _creer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Créer la formation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: maxLines == 1 ? Icon(icone, color: const Color(0xFF00796B), size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _selectedColor, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color couleur;
  const _SectionLabel({required this.icone, required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, color: couleur, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
      ],
    );
  }
}

// ── Bottom sheet ajout de session ──────────────────────────────────────────────
class _AddSessionSheet extends StatefulWidget {
  final Color couleur;
  final String formationTitre;
  const _AddSessionSheet({required this.couleur, required this.formationTitre});

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  final _titreCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _heureDebut = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _heureFin = const TimeOfDay(hour: 11, minute: 0);
  int _maxParticipants = 20;
  String? _formateurId;
  String _formateurNom = '';
  List<Map<String, dynamic>> _formateurs = [];
  bool _loadingFormateurs = true;

  @override
  void initState() {
    super.initState();
    _loadFormateurs();
  }

  Future<void> _loadFormateurs() async {
    final list = await FormationService().getFormateurs();
    if (mounted) setState(() { _formateurs = list; _loadingFormateurs = false; });
  }

  @override
  void dispose() { _titreCtrl.dispose(); super.dispose(); }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: widget.couleur)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickDebut() async {
    final picked = await showTimePicker(
      context: context, initialTime: _heureDebut,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: widget.couleur)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _heureDebut = picked);
  }

  Future<void> _pickFin() async {
    final picked = await showTimePicker(
      context: context, initialTime: _heureFin,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: widget.couleur)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _heureFin = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Nouvelle session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.couleur)),
            const SizedBox(height: 20),

            // Titre
            TextField(
              controller: _titreCtrl,
              decoration: InputDecoration(
                labelText: 'Titre de la session',
                prefixIcon: const Icon(Icons.event_note_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.couleur, width: 2)),
              ),
            ),
            const SizedBox(height: 14),

            // Date
            _PickerRow(
              icone: Icons.calendar_today_outlined,
              label: 'Date',
              valeur: '${_date.day.toString().padLeft(2,'0')}/${_date.month.toString().padLeft(2,'0')}/${_date.year}',
              couleur: widget.couleur,
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),

            // Heures
            Row(children: [
              Expanded(child: _PickerRow(icone: Icons.schedule_outlined, label: 'Heure début',
                  valeur: _fmt(_heureDebut), couleur: widget.couleur, onTap: _pickDebut)),
              const SizedBox(width: 10),
              Expanded(child: _PickerRow(icone: Icons.schedule_outlined, label: 'Heure fin',
                  valeur: _fmt(_heureFin), couleur: widget.couleur, onTap: _pickFin)),
            ]),
            const SizedBox(height: 14),

            // Formateur
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)),
              child: _loadingFormateurs
                  ? const Padding(padding: EdgeInsets.all(12),
                  child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))))
                  : _formateurs.isEmpty
                  ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    Icon(Icons.person_outline, color: widget.couleur, size: 20),
                    const SizedBox(width: 8),
                    Text('Aucun formateur disponible',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  ]))
                  : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Row(children: [
                    Icon(Icons.person_outline, color: widget.couleur, size: 20),
                    const SizedBox(width: 8),
                    Text('Choisir un formateur',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  ]),
                  value: _formateurId,
                  icon: Icon(Icons.keyboard_arrow_down, color: widget.couleur),
                  onChanged: (id) {
                    if (id == null) return;
                    final f = _formateurs.firstWhere((f) => f['id'] == id);
                    setState(() { _formateurId = id; _formateurNom = f['nom'] as String; });
                  },
                  items: _formateurs.map((f) {
                    return DropdownMenuItem<String>(
                      value: f['id'] as String,
                      child: Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: widget.couleur.withValues(alpha: 0.15),
                          child: Text(
                            (f['nom'] as String).isNotEmpty ? (f['nom'] as String)[0].toUpperCase() : '?',
                            style: TextStyle(color: widget.couleur, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(f['nom'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Text(f['email'] as String,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ],
                        )),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Participants max
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.group_outlined, color: widget.couleur, size: 20),
                const SizedBox(width: 10),
                const Text('Participants max', style: TextStyle(fontSize: 14)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  onPressed: _maxParticipants > 1 ? () => setState(() => _maxParticipants--) : null,
                  color: widget.couleur,
                ),
                SizedBox(width: 32,
                    child: Text('$_maxParticipants', textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  onPressed: () => setState(() => _maxParticipants++),
                  color: widget.couleur,
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Bouton valider
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_titreCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez saisir un titre'), backgroundColor: Colors.orange));
                    return;
                  }
                  Navigator.pop(context, SessionModel(
                    id: '', formationId: '',
                    formateurId: _formateurId ?? '',
                    formateurNom: _formateurNom,
                    date: _date,
                    heureDebut: _fmt(_heureDebut),
                    heureFin: _fmt(_heureFin),
                    participantsIds: const [],
                    statut: 'planifiee',
                    titre: _titreCtrl.text.trim(),
                    maxParticipants: _maxParticipants,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.couleur,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Ajouter cette session',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Ligne sélecteur date/heure ─────────────────────────────────────────────────
class _PickerRow extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;
  final Color couleur;
  final VoidCallback onTap;
  const _PickerRow({required this.icone, required this.label, required this.valeur,
    required this.couleur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icone, color: couleur, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              Text(valeur, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          )),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
        ]),
      ),
    );
  }
}