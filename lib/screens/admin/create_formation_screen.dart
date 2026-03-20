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

  final List<String> _thematiques = [
    'inclusion',
    'environnement',
    'egalite',
    'tolerance',
    'citoyennete',
  ];

  Future<void> _creer() async {
    if (_titreCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
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
            backgroundColor: Colors.teal,
          ));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une formation'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Titre de la formation',
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titreCtrl,
              decoration: const InputDecoration(
                hintText: 'Ex: Inclusion et diversité',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Thématique',
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _thematique,
              decoration: const InputDecoration(
                border: OutlineInputBorder()),
              items: _thematiques.map((t) =>
                DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _thematique = v!),
            ),
            const SizedBox(height: 24),
            const Text('Description',
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Décrivez le contenu de la formation...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _creer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Créer la formation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}