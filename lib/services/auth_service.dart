import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Inscription avec gestion d'erreurs et typage
  Future<String> register(String email, String password, String nom, String role) async {
    try {
      // 1. Création du compte dans Firebase Auth
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Création du document utilisateur dans Firestore
      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': email.toLowerCase().trim(),
          'nom': nom,
          'role': role, // 'benevole', 'formateur', ou 'admin'
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      return role;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Une erreur inattendue est survenue lors de l\'inscription.';
    }
  }

  // Connexion et récupération du rôle
  Future<String> login(String email, String password) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      // Récupération du rôle dans Firestore
      final DocumentSnapshot doc = await _db.collection('users')
          .doc(cred.user!.uid).get();

      if (!doc.exists) {
        throw 'Profil utilisateur introuvable en base de données.';
      }

      // Mise à jour de la date de dernière connexion
      await _db.collection('users').doc(cred.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return doc.get('role') as String;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Erreur de connexion : ${e.toString()}';
    }
  }

  // Récupérer les données complètes de l'utilisateur actuel (très utile pour le Dashboard)
  Stream<DocumentSnapshot> get userProfile {
    final uid = _auth.currentUser?.uid;
    return _db.collection('users').doc(uid).snapshots();
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Getters utiles
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  // Centralisation des messages d'erreur (plus pro pour l'utilisateur)
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé pour cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      default:
        return 'Erreur d\'authentification : ${e.message}';
    }
  }
}