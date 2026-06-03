import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nuevaCtrl = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _loading    = false;
  bool _mostrar1   = false;
  bool _mostrar2   = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.cambiarContrasena(_nuevaCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ContraseÃ±a cambiada exitosamente'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseÃ±a')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nuevaCtrl,
                obscureText: !_mostrar1,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseÃ±a',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_mostrar1 ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _mostrar1 = !_mostrar1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 8) return 'MÃ­nimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confCtrl,
                obscureText: !_mostrar2,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseÃ±a',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_mostrar2 ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _mostrar2 = !_mostrar2)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v != _nuevaCtrl.text ? 'Las contraseÃ±as no coinciden' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _guardar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar contraseÃ±a'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }
}
