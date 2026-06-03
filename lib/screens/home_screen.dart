import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _perfil;
  String? _qrPayload;
  int     _segundos = 240;
  Timer?  _timer;
  bool    _cargando = true;
  late TabController _tabs;

  // Para admin/proveedor
  List<Map<String, dynamic>> _transacciones = [];
  bool _cargandoTx = false;

  final _supabase = Supabase.instance.client;
  final _fmt = DateFormat('dd/MM HH:mm');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _puedeVerHistorial ? 2 : 1, vsync: this);
    _cargarPerfil();
  }

  bool get _puedeVerHistorial {
    final rol = widget.perfil?['rol'] ?? '';
    return rol == 'proveedor' || rol == 'admin_empresa';
  }

  Future<void> _cargarPerfil() async {
    try {
      if (widget.perfil != null) {
        setState(() { _perfil = widget.perfil; _cargando = false; });
      } else {
        final user = _supabase.auth.currentUser;
        if (user == null) return;
        final data = await _supabase
            .from('usuarios')
            .select('*, empresa:empresas(nombre)')
            .eq('auth_user_id', user.id)
            .maybeSingle();
        setState(() { _perfil = data; _cargando = false; });
      }
      _iniciarTimerQR();
      if (_puedeVerHistorial) _cargarTransacciones();
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _iniciarTimerQR() {
    _generarQR();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final secs = QrService.secondsUntilNextWindow();
      setState(() => _segundos = secs);
      if (secs <= 1) _generarQR();
    });
  }

  void _generarQR() {
    if (_perfil == null) return;
    final payload = QrService.generateQRPayload(
      _perfil!['id'] as String,
      (_perfil!['qr_secret'] ?? _perfil!['id']) as String,
    );
    setState(() {
      _qrPayload = payload;
      _segundos  = QrService.secondsUntilNextWindow();
    });
  }

  Future<void> _cargarTransacciones() async {
    if (_perfil == null) return;
    setState(() => _cargandoTx = true);
    try {
      final data = await _supabase
          .from('transacciones')
          .select('tipo, resultado, fecha, torre:torre_id(nombre), usuario:usuario_id(nombres, apellidos, empresa_id)')
          .order('fecha', ascending: false)
          .limit(100);

      var lista = List<Map<String, dynamic>>.from(data);

      // Filtrar por empresa si es admin
      if (_perfil!['rol'] == 'admin_empresa' && _perfil!['empresa_id'] != null) {
        lista = lista.where((t) =>
          t['usuario']?['empresa_id'] == _perfil!['empresa_id']
        ).toList();
      }

      setState(() => _transacciones = lista.take(50).toList());
    } catch (e) {
      debugPrint('Error cargando transacciones: $e');
    }
    setState(() => _cargandoTx = false);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final rol = _perfil?['rol'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0FF),
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Text('Ciudad del Rio', style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: _puedeVerHistorial ? TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'Mi QR'),
            Tab(icon: Icon(Icons.history), text: 'Ingresos'),
          ],
        ) : null,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'pass') Navigator.push(context, MaterialPageRoute(builder: (_) => const CambiarContrasenaScreen()));
              if (val == 'salir') _logout();
              if (val == 'refresh') _cargarTransacciones();
            },
            itemBuilder: (_) => [
              if (_puedeVerHistorial)
                const PopupMenuItem(value: 'refresh', child: Text('Actualizar historial')),
              const PopupMenuItem(value: 'pass',  child: Text('Cambiar contraseÃ±a')),
              const PopupMenuItem(value: 'salir', child: Text('Cerrar sesiÃ³n')),
            ],
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _puedeVerHistorial
              ? TabBarView(
                  controller: _tabs,
                  children: [_buildQRTab(cs), _buildHistorialTab(cs)],
                )
              : _buildQRTab(cs),
    );
  }

  // ---- Pantalla QR ----
  Widget _buildQRTab(ColorScheme cs) {
    final iniciales = '${_perfil?['nombres']?[0] ?? ''}${_perfil?['apellidos']?[0] ?? ''}'.toUpperCase();
    final pct = _segundos / 240.0;
    final colorTimer = _segundos <= 30 ? Colors.orange : cs.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Info usuario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Row(
              children: [
                CircleAvatar(radius: 26, backgroundColor: cs.primary,
                    child: Text(iniciales, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_perfil?['nombres'] ?? ''} ${_perfil?['apellidos'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (_perfil?['cargo'] != null)
                    Text(_perfil!['cargo'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta QR
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15)]),
            child: Column(children: [
              const Text('CÃ³digo de acceso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Presenta en el torniquete', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),

              if (_qrPayload != null)
                QrImageView(
                  data: _qrPayload!,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: const Color(0xFF4F46E5)),
                  dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: const Color(0xFF1E1B4B)),
                )
              else
                Container(width: 220, height: 220, color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator())),

              const SizedBox(height: 16),

              // Timer
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Cambia en', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${_segundos}s', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorTimer)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(colorTimer),
                ),
              ),
              const SizedBox(height: 16),

              // Boton actualizar QR
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _generarQR,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar QR ahora'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),

          if (_perfil?['cedula'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.badge_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text('CC ${_perfil!['cedula']}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Pantalla Historial ----
  Widget _buildHistorialTab(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Ingresos y salidas recientes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              IconButton(onPressed: _cargarTransacciones, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
            ],
          ),
        ),
        if (_cargandoTx)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_transacciones.isEmpty)
          const Expanded(child: Center(child: Text('Sin registros aÃºn', style: TextStyle(color: Colors.grey))))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _transacciones.length,
              itemBuilder: (ctx, i) {
                final t = _transacciones[i];
                final esEntrada = t['tipo'] == 'entrada';
                final esAprobado = t['resultado'] == 'aprobado';
                final nombre = '${t['usuario']?['nombres'] ?? ''} ${t['usuario']?['apellidos'] ?? ''}'.trim();
                final torre  = t['torre']?['nombre'] ?? 'â€”';
                final fecha  = t['fecha'] != null ? _fmt.format(DateTime.parse(t['fecha']).toLocal()) : 'â€”';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: esAprobado
                        ? (esEntrada ? Colors.green[100] : Colors.blue[100])
                        : Colors.red[100],
                    child: Icon(
                      esEntrada ? Icons.login : Icons.logout,
                      color: esAprobado
                          ? (esEntrada ? Colors.green[700] : Colors.blue[700])
                          : Colors.red[700],
                      size: 20,
                    ),
                  ),
                  title: Text(nombre.isEmpty ? 'Usuario' : nombre,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('$torre Â· $fecha', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: esAprobado ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      esAprobado ? (esEntrada ? 'EntrÃ³' : 'SaliÃ³') : 'Rechazado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: esAprobado ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
