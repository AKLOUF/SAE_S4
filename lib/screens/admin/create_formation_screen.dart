import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateFormationScreen extends StatefulWidget {
  const CreateFormationScreen({super.key});

  @override
  State<CreateFormationScreen> createState() =>
      _CreateFormationScreenState();
}

class _CreateFormationScreenState extends State<CreateFormationScreen> {
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _thematique = 'inclusion';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _thematiques = [
    {'valeur': 'inclusion', 'label': 'Inclusion',
      'icone': Icons.people, 'couleur': const Color(0xFF7C3AED)},
    {'valeur': 'environnement', 'label': 'Environnement',
      'icone': Icons.eco, 'couleur': const Color(0xFF059669)},
    {'valeur': 'egalite', 'label': 'Égalité',
      'icone': Icons.balance, 'couleur': const Color(0xFFDC2626)},
    {'valeur': 'tolerance', 'label': 'Tolérance',
      'icone': Icons.handshake, 'couleur': const Color(0xFFD97706)},
    {'valeur': 'citoyennete', 'label': 'Citoyenneté',
      'icone': Icons.account_balance, 'couleur': const Color(0xFF2563EB)},
  ];

  Future<void> _creer() async {
    if (_titreCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('Formations').add({
        'titre': _titreCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'thematique': _thematique,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formation créée avec succès !'),
            backgroundColor: Color(0xFF00796B)));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création'),
          backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color get _selectedColor {
    final t = _thematiques.firstWhere(
      (t) => t['valeur'] == _thematique);
    return t['couleur'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nouvelle formation',
          style: TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back,
              color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Titre
            _SectionLabel(
              icone: Icons.title,
              label: 'Titre de la formation',
              couleur: _selectedColor),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _titreCtrl,
              hint: 'Ex: Inclusion et diversité',
              icone: Icons.edit_outlined,
              maxLines: 1,
            ),

            const SizedBox(height: 24),

            // Thématique
            _SectionLabel(
              icone: Icons.category_outlined,
              label: 'Thématique',
              couleur: _selectedColor),
            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
              itemCount: _thematiques.length,
              itemBuilder: (context, i) {
                final t = _thematiques[i];
                final selected = _thematique == t['valeur'];
                final color = t['couleur'] as Color;
                return GestureDetector(
                  onTap: () => setState(
                    () => _thematique = t['valeur'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? color
                            : Colors.grey.shade200,
                        width: 2),
                      boxShadow: selected ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                      ] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t['icone'] as IconData,
                          color: selected
                              ? Colors.white
                              : color,
                          size: 24),
                        const SizedBox(height: 6),
                        Text(t['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF1A1A2E))),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Description
            _SectionLabel(
              icone: Icons.description_outlined,
              label: 'Description',
              couleur: _selectedColor),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _descCtrl,
              hint: 'Décrivez le contenu et les objectifs de cette formation...',
              icone: Icons.notes_outlined,
              maxLines: 5,
            ),

            const SizedBox(height: 32),

            // Aperçu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedColor.withOpacity(0.2))),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      (_thematiques.firstWhere(
                        (t) => t['valeur'] == _thematique)
                        ['icone']) as IconData,
                      color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titreCtrl.text.isEmpty
                              ? 'Titre de la formation'
                              : _titreCtrl.text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _titreCtrl.text.isEmpty
                                ? Colors.grey
                                : const Color(0xFF1A1A2E))),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _selectedColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(_thematique,
                            style: TextStyle(
                              color: _selectedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
                child: _isLoading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Créer la formation',
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
        prefixIcon: maxLines == 1
            ? Icon(icone, color: const Color(0xFF00796B), size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _selectedColor, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icone;
  final String label;
  final Color couleur;

  const _SectionLabel({
    required this.icone,
    required this.label,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, color: couleur, size: 18),
        const SizedBox(width: 8),
        Text(label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E))),
      ],
    );
  }
}