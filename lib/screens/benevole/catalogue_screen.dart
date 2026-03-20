import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../benevole/login_screen.dart';
import 'formation_detail_screen.dart';

class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formations disponibles'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        toolbarHeight: kToolbarHeight,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Formations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune formation disponible',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          final formations = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: formations.length,
            itemBuilder: (context, i) {
              final data = formations[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      data['titre']?[0] ?? 'F',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(data['titre'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['thematique'] ?? ''),
                      const SizedBox(height: 4),
                      Text(data['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.teal),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FormationDetailScreen(
                      formationId: formations[i].id,
                      titre: data['titre'] ?? '',
                      description: data['description'] ?? '',
                      thematique: data['thematique'] ?? '',
                    ))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}