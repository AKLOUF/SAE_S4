import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'catalogue_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _authService = AuthService();
  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      String role;
      if (_isLogin) {
        role = await _authService.login(
          _emailCtrl.text.trim(),
          _passCtrl.text.trim(),
        );
      } else {
        role = await _authService.register(
          _emailCtrl.text.trim(),
          _passCtrl.text.trim(),
          _nomCtrl.text.trim(),
          'benevole',
        );
      }
      if (mounted) {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const CatalogueScreen()));
      }
    } catch (e) {
      setState(() { _error = 'Erreur : vérifiez vos informations'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('OpenMinds',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.teal, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Formation citoyenne',
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 40),
              if (!_isLogin)
                TextField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              if (!_isLogin) const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 8),
              if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLogin ? 'Se connecter' : "S'inscrire"),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                  ? 'Pas de compte ? S\'inscrire'
                  : 'Déjà un compte ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}