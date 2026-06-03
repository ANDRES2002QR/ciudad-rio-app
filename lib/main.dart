import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Reemplaza estos valores con los de tu proyecto Supabase
const String supabaseUrl  = 'https://yqcvhntfmsmdfnjxdlrr.supabase.co';
const String supabaseKey  = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxY3ZobnRmbXNtZGZuanhkbHJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzNTQ5NTQsImV4cCI6MjA5NTkzMDk1NH0.58Mtv1UXSOj4Re61HuCrHRcfWant4fTnxj2eDlnSKpA';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const CiudadRioApp());
}

class CiudadRioApp extends StatelessWidget {
  const CiudadRioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ciudad del Rio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

