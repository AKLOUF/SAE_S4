import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../benevole/login_screen.dart';
import 'create_formation_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle formation'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const CreateFormationScreen())),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statistiques globales',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Nombre de formations
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Formations').snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return _StatCard(
                  titre: 'Formations',
                  valeur: '$count',
                  icone: Icons.school,
                  couleur: Colors.teal,
                );
              },
            ),
            const SizedBox(height: 12),

            // Nombre d'utilisateurs
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return _StatCard(
                  titre: 'Bénévoles inscrits',
                  valeur: '$count',
                  icone: Icons.people,
                  couleur: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 32),

            const Text('Formations disponibles',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Formations').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const CircularProgressIndicator();
                }
                final formations = snap.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: formations.length,
                  itemBuilder: (context, i) {
                    final data =
                        formations[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(
                            data['titre']?[0] ?? 'F',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(data['titre'] ?? ''),
                        subtitle: Text(data['thematique'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatCard({
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valeur,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: couleur,
                )),
              Text(titre,
                style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}