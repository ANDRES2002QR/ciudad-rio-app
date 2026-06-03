import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/qr_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'cambiar_contrasena_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? perfil;

  const HomeScreen({super.key, this.perfil});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _perfil;
  String? _qrPayload;
  int _segundosRestantes = 0;
  Timer? _timer;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      if (widget.perfil != null) {
        setState(() { _perfil = widget.perfil; _cargando = false; });
      } else {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;
        final data = await Supabase.instance.client
            .from('usuarios')
            .select('*, empresa:empresas(nombre)')
            .eq('auth_user_id', user.id)
            .single();
        setState(() { _perfil = data; _cargando = false; });
      }
      _iniciarTimerQR();
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _iniciarTimerQR() {
    _generarQR();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final secs = QrService.secondsUntilNextWindow();
      setState(() => _segundosRestantes = secs);
      if (secs <= 1) _generarQR();
    });
  }

  void _generarQR() {
    if (_perfil == null) return;
    final payload = QrService.generateQRPayload(_perfil!['id'], _perfil!['qr_secret']);
    setState(() {
      _qrPayload         = payload;
      _segundosRestantes = QrService.secondsUntilNextWindow();
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final rol = _perfil?['rol'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: const Text('Ciudad del Rio', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'contrasena') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CambiarContrasenaScreen()));
              } else if (val == 'salir') {
                _logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'contrasena', child: Text('Cambiar contraseÃ±a')),
              const PopupMenuItem(value: 'salir', child: Text('Cerrar sesiÃ³n')),
            ],
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info del usuario
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: cs.primary,
                          child: Text(
                            '${_perfil?['nombres']?[0] ?? ''}${_perfil?['apellidos']?[0] ?? ''}'.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${_perfil?['nombres'] ?? ''} ${_perfil?['apellidos'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (_perfil?['cargo'] != null) Text(_perfil!['cargo'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              if (_perfil?['empresa'] != null) Text(_perfil!['empresa']['nombre'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // QR principal
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15)]),
                    child: Column(
                      children: [
                        const Text('Tu cÃ³digo de acceso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 4),
                        const Text('Presenta este QR en el torniquete', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 20),

                        if (_qrPayload != null)
                          QrImageView(
                            data: _qrPayload!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: const Color(0xFF4F46E5),
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Temporizador
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: _segundosRestantes <= 30 ? Colors.orange : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Cambia en $_segundosRestantes segundos',
                              style: TextStyle(
                                fontSize: 13,
                                color: _segundosRestantes <= 30 ? Colors.orange.shade700 : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Barra de progreso del tiempo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _segundosRestantes / (QrService.secondsUntilNextWindow() + (240 - _segundosRestantes)).clamp(1, 240).toDouble(),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              _segundosRestantes <= 30 ? Colors.orange : cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info de cedula
                  if (_perfil?['cedula'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 16, color: cs.primary),
                          const SizedBox(width: 8),
                          Text('CC ${_perfil!['cedula']}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                  // Si es admin, mostrar boton para ir al panel mini
                  if (rol == 'admin_empresa') ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Tu QR de acceso estÃ¡ arriba.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Text('Gestiona tu equipo desde la pÃ¡gina web.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ],
              ),
            ),
    );
  }
}
