import 'dart:convert';
import 'package:crypto/crypto.dart';

// Mismo algoritmo que el web (HMAC-SHA256 + ventana de 4 minutos)
// Compatible con la validacion de la app C# del torniquete.

class QrService {
  static const int _windowMinutes = 4;

  static int currentWindow() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now ~/ (_windowMinutes * 60 * 1000);
  }

  static int secondsUntilNextWindow() {
    final windowMs = _windowMinutes * 60 * 1000;
    final elapsed  = DateTime.now().millisecondsSinceEpoch % windowMs;
    return ((windowMs - elapsed) / 1000).ceil();
  }

  // Genera el HMAC-SHA256 del mensaje con la clave secreta
  static String _hmacSha256(String secret, String message) {
    final key   = utf8.encode(secret);
    final msg   = utf8.encode(message);
    final hmac  = Hmac(sha256, key);
    final digest = hmac.convert(msg);
    return digest.toString();
  }

  // Token para una ventana especifica
  static String generateToken(String userId, String secret, int window) {
    return _hmacSha256(secret, '$userId:$window');
  }

  // Payload completo para el QR: base64(userId:token)
  static String generateQRPayload(String userId, String secret) {
    final win   = currentWindow();
    final token = generateToken(userId, secret, win);
    return base64.encode(utf8.encode('$userId:$token'));
  }

  // Valida un payload (para testing; la validacion real ocurre en el torniquete/C#)
  static bool validateQRPayload(String payload, String userId, String secret) {
    try {
      final decoded = utf8.decode(base64.decode(payload));
      final parts   = decoded.split(':');
      if (parts.length < 2 || parts[0] != userId) return false;

      final presentedToken = parts[1];
      final win = currentWindow();

      final tokenNow  = generateToken(userId, secret, win);
      final tokenPrev = generateToken(userId, secret, win - 1);

      return presentedToken == tokenNow || presentedToken == tokenPrev;
    } catch (_) {
      return false;
    }
  }
}
