import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _supabase.auth.signInWithPassword(email: email, password: password);
    if (res.session == null) throw Exception('Credenciales incorrectas');

    // Cargar perfil del usuario
    final perfil = await _supabase
        .from('usuarios')
        .select('*, empresa:empresas(id, nombre)')
        .eq('auth_user_id', res.user!.id)
        .single();

    // Empleados pueden usar la app; admins tambien (para ver su QR)
    if (perfil['rol'] == null) throw Exception('Usuario sin rol asignado');

    return perfil;
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  static Future<void> cambiarContrasena(String nuevaContrasena) async {
    final res = await _supabase.auth.updateUser(UserAttributes(password: nuevaContrasena));
    if (res.user == null) throw Exception('No se pudo cambiar la contraseÃ±a');
  }

  static Map<String, dynamic>? get perfilActual => null; // se carga en HomeScreen
}
