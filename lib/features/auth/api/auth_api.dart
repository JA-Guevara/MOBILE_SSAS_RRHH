import '../../../core/errors/app_exception.dart';
import '../../../shared/api/http_client.dart';

class AuthSession {
  const AuthSession({required this.accessToken, this.userName});
  final String accessToken;
  final String? userName;
}

class AuthApi {
  const AuthApi(this._client);
  final AppHttpClient _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    if (response is! Map<String, dynamic>) {
      throw const AppException('Respuesta de inicio de sesión inválida.');
    }
    final token = response['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const AppException('El servidor no devolvió un token de acceso.');
    }
    return AuthSession(
      accessToken: token,
      userName: response['user_name']?.toString(),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
  }
}
