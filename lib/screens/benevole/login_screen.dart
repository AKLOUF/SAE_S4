import 'package:flutter/material.dart';
import 'package:openminds/screens/formateur/sessions_screen.dart';
import '../../services/auth_service.dart';
import '../benevole/catalogue_screen.dart';
import '../admin/stats_screen.dart';

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
  bool _obscurePass = true;
  String _error = '';
  String _roleSelectionne = 'benevole';

  Future<void> _submit() async {
    // ── Fix 1 : validation complète avant envoi ──────────
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }
    // ── Fix 2 : valider le nom et le mot de passe à l'inscription
    if (!_isLogin) {
      if (_nomCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Veuillez saisir votre nom complet');
        return;
      }
      if (_passCtrl.text.trim().length < 6) {
        setState(() => _error = 'Le mot de passe doit contenir au moins 6 caractères');
        return;
      }
    }

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
          _roleSelectionne,
        );
      }

      if (mounted) {
        Widget nextScreen;
        switch (role) {
          case 'admin':
            nextScreen = const StatsScreen();
            break;
          case 'formateur':
            nextScreen = const SessionsScreen();
            break;
          default:
            nextScreen = const CatalogueScreen();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      // ── Fix 3 : afficher le vrai message d'erreur de AuthService ──
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00796B), Color(0xFF004D40)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec logo custom
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(painter: _LogoPainter()),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'OpenMinds',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Formation citoyenne',
                        style:
                        TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              // Formulaire blanc arrondi
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin ? 'Connexion' : 'Créer un compte',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLogin
                              ? 'Bienvenue ! Connectez-vous pour continuer.'
                              : 'Rejoignez la communauté OpenMinds.',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),

                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nomCtrl,
                            label: 'Nom complet',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(),
                          const SizedBox(height: 16),
                        ],

                        _buildTextField(
                          controller: _emailCtrl,
                          label: 'Adresse email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passCtrl,
                          label: 'Mot de passe',
                          icon: Icons.lock_outline,
                          obscure: _obscurePass,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                          ),
                        ),

                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border:
                              Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade400, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error,
                                      style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                                : Text(
                                _isLogin ? 'Se connecter' : "S'inscrire",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() {
                              _isLogin = !_isLogin;
                              _error = '';
                            }),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14),
                                children: [
                                  TextSpan(
                                      text: _isLogin
                                          ? 'Pas de compte ? '
                                          : 'Déjà un compte ? '),
                                  TextSpan(
                                      text: _isLogin
                                          ? "S'inscrire"
                                          : 'Se connecter',
                                      style: const TextStyle(
                                          color: Color(0xFF00796B),
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
        Icon(icon, color: const Color(0xFF00796B), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF00796B), width: 2)),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _roleSelectionne,
      decoration: InputDecoration(
        labelText: 'Rôle utilisateur',
        prefixIcon: const Icon(Icons.badge_outlined,
            color: Color(0xFF00796B), size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      items: const [
        DropdownMenuItem(value: 'benevole', child: Text('Bénévole')),
        DropdownMenuItem(value: 'formateur', child: Text('Formateur')),
      ],
      onChanged: (v) => setState(() => _roleSelectionne = v!),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    const Color tealColor = Color(0xFF00796B);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(22)),
        bgPaint);

    final circlePaint = Paint()
      ..color = tealColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(Offset(cx, cy), 32, circlePaint);

    final innerPaint = Paint()
      ..color = tealColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(cx, cy), 22, innerPaint);

    final centerPaint = Paint()
      ..color = tealColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(cx, cy), 13, centerPaint);

    final linePaint = Paint()
      ..color = tealColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx, cy - 17), Offset(cx, cy - 26), linePaint);
    canvas.drawLine(
        Offset(cx, cy + 17), Offset(cx, cy + 26), linePaint);
    canvas.drawLine(
        Offset(cx - 17, cy), Offset(cx - 26, cy), linePaint);
    canvas.drawLine(
        Offset(cx + 17, cy), Offset(cx + 26, cy), linePaint);

    canvas.drawCircle(
        Offset(cx, cy), 4, Paint()..color = tealColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}