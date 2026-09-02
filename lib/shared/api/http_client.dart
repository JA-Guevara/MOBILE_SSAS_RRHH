import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';

/// Cliente HTTP de la app.
///
/// Usa `package:http` y NO `dart:io`. La razón es que `dart:io` no existe en
/// el navegador: con él, `flutter run -d chrome` ni siquiera compila, y las
/// capturas de evidencia se toman en Chrome. `package:http` funciona igual
/// en web, Android, iOS y Windows, y ya estaba en pubspec.yaml.
///
/// La API pública no cambió: get, post y close se usan igual que antes.
class AppHttpClient {
  AppHttpClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;

  Future<Object?> get(String path, {String? accessToken}) =>
      _request('GET', path, accessToken: accessToken);
  Future<Object?> post(
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) => _request('POST', path, body: body, accessToken: accessToken);

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = <String, String>{
        'content-type': 'application/json; charset=utf-8',
        if (accessToken != null) 'authorization': 'Bearer $accessToken',
      };

      final response = method == 'GET'
          ? await _client.get(uri, headers: headers)
          : await _client.post(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            );

      // Se decodifica en UTF-8 a mano: response.body usa latin1 cuando el
      // servidor no manda charset, y ahí se rompen las tildes y las ñ.
      final rawBody = utf8.decode(response.bodyBytes);
      final data = rawBody.isEmpty ? null : jsonDecode(rawBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map<String, dynamic>
            ? data['detail']?.toString() ?? 'La solicitud no pudo completarse.'
            : 'La solicitud no pudo completarse.';
        throw AppException(message, statusCode: response.statusCode);
      }
      return data;
    } on AppException {
      rethrow;
    } on Object {
      throw const AppException('No se pudo conectar con el servidor.');
    }
  }

  void close() => _client.close();
}
