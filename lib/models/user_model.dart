class UserModel {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String role; // 'benevole', 'formateur', 'admin'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      role: map['role'] ?? 'benevole',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'createdAt': createdAt,
    };
  }
}