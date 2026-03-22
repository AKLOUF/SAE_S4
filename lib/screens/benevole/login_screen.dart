import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../benevole/catalogue_screen.dart';
import '../admin/stats_screen.dart';
import '../formateur/participants_screen.dart';

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
        if (role == 'admin') {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const StatsScreen()));
        } else if (role == 'formateur') {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ParticipantsScreen()));
        } else {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CatalogueScreen()));
        }
      }
    } catch (e) {
      setState(() { _error = 'Email ou mot de passe incorrect'; });
    } finally {
      setState(() { _isLoading = false; });
    }
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
              // Header avec logo
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                      painter: _LogoPainter(),
                      ),
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Formation citoyenne',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Formulaire
              Expanded(
                flex: 3,
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
                        const SizedBox(height: 8),
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
                            fontSize: 13,
                            color: Colors.grey.shade600),
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
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
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

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
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
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  _isLogin ? 'Se connecter' : "S'inscrire",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
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
                                  color: Colors.grey.shade600, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: _isLogin
                                      ? 'Pas de compte ? '
                                      : 'Déjà un compte ? '),
                                  TextSpan(
                                    text: _isLogin ? 'S\'inscrire' : 'Se connecter',
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
        prefixIcon: Icon(icon, color: const Color(0xFF00796B), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00796B), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _roleSelectionne,
      decoration: InputDecoration(
        labelText: 'Rôle',
        prefixIcon: const Icon(Icons.badge_outlined,
          color: Color(0xFF00796B), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00796B), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'benevole',
          child: Text('Bénévole')),
        DropdownMenuItem(value: 'formateur',
          child: Text('Formateur')),
        DropdownMenuItem(value: 'admin',
          child: Text('Administrateur')),
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

    // Fond blanc arrondi
    final bgPaint = Paint()..color = Colors.white;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(22),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Cercle extérieur teal
    final circlePaint = Paint()
      ..color = const Color(0xFF00796B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(Offset(cx, cy), 32, circlePaint);

    // Cercle intérieur rempli
    final innerPaint = Paint()
      ..color = const Color(0xFF00796B).withOpacity(0.15);
    canvas.drawCircle(Offset(cx, cy), 22, innerPaint);

    // Lettre O - cercle central
    final centerPaint = Paint()
      ..color = const Color(0xFF00796B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(cx, cy), 13, centerPaint);

    // 4 traits rayonnants comme une boussole
    final linePaint = Paint()
      ..color = const Color(0xFF00796B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Haut
    canvas.drawLine(
      Offset(cx, cy - 17), Offset(cx, cy - 26), linePaint);
    // Bas
    canvas.drawLine(
      Offset(cx, cy + 17), Offset(cx, cy + 26), linePaint);
    // Gauche
    canvas.drawLine(
      Offset(cx - 17, cy), Offset(cx - 26, cy), linePaint);
    // Droite
    canvas.drawLine(
      Offset(cx + 17, cy), Offset(cx + 26, cy), linePaint);

    // Point central
    final dotPaint = Paint()..color = const Color(0xFF00796B);
    canvas.drawCircle(Offset(cx, cy), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}