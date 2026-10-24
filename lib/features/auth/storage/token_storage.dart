import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clear();
}

class MemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  @override
  Future<String?> readAccessToken() async => _accessToken;
  @override
  Future<void> saveAccessToken(String token) async => _accessToken = token;
  @override
  Future<void> clear() async => _accessToken = null;
}

/// El token guardado en el almacenamiento seguro del teléfono, con la
/// misma clave que ya usan login_screen.dart y AuthInterceptor
/// ("access_token"). Es el que usan los servicios REALES del Sprint 3:
/// cuando el login guarde el token de verdad, ellos lo leerán sin cambios.
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();

  static const _clave = 'access_token';
  static const _almacen = FlutterSecureStorage();

  @override
  Future<String?> readAccessToken() => _almacen.read(key: _clave);
  @override
  Future<void> saveAccessToken(String token) =>
      _almacen.write(key: _clave, value: token);
  @override
  Future<void> clear() => _almacen.delete(key: _clave);
}
