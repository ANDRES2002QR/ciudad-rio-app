import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool  _loading      = false;
  bool  _mostrarPass  = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final perfil = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(perfil: perfil)),
      );
    } catch (e) {
      setState(() => _error = 'Email o contraseÃ±a incorrectos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.lock_outline_rounded, size: 40, color: cs.primary),
                ),
                const SizedBox(height: 20),
                const Text('Ciudad del Rio', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Control de Acceso', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 40),

                // Card de login
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrÃ³nico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),

                        // ContraseÃ±a
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_mostrarPass,
                          decoration: InputDecoration(
                            labelText: 'ContraseÃ±a',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_mostrarPass ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _mostrarPass = !_mostrarPass),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 24),

                        // Boton
                        FilledButton(
                          onPressed: _loading ? null : _login,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Â¿Olvidaste tu contraseÃ±a? Contacta a tu administrador.', style: TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
