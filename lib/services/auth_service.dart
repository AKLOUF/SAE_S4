import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Inscription
  Future<String> register(String email, String password,
      String nom, String role) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password);
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'nom': nom,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return role;
  }

  // Connexion
  Future<String> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password);
    final doc = await _db.collection('users')
        .doc(cred.user!.uid).get();
    return doc.data()!['role'] as String;
  }

  // Déconnexion
  Future<void> logout() => _auth.signOut();

  // Utilisateur courant
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
}