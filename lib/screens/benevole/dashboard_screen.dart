import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon parcours'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes badges',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('badges').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Aucun badge pour le moment',
                        style: TextStyle(color: Colors.grey)),
                    ]),
                  );
                }
                final badges = snapshot.data!.docs;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                  itemCount: badges.length,
                  itemBuilder: (context, i) {
                    final data = badges[i].data() as Map<String, dynamic>;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 36),
                          const SizedBox(height: 8),
                          Text(data['titre'] ?? 'Badge',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('Mes résultats',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('quiz_results')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Aucun quiz complété pour le moment',
                        style: TextStyle(color: Colors.grey)),
                    ]),
                  );
                }
                final results = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final data = results[i].data() as Map<String, dynamic>;
                    final score = (data['score'] as num).toDouble();
                    final reussi = score >= 70;
                    final titre = data['titre']?.toString() ?? 'Formation';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                            reussi ? Colors.teal : Colors.red.shade100,
                          child: Text(
                            '${score.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: reussi ? Colors.white : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(titre,
                          style: const TextStyle(fontSize: 14)),
                        trailing: Icon(
                          reussi ? Icons.check_circle : Icons.cancel,
                          color: reussi ? Colors.teal : Colors.red,
                        ),
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