import 'dart:convert';
import 'dart:io';

import '../../core/errors/app_exception.dart';

class AppHttpClient {
  AppHttpClient({required this.baseUrl, HttpClient? client})
    : _client = client ?? HttpClient();
  final String baseUrl;
  final HttpClient _client;

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
      final request = await _client.openUrl(method, Uri.parse('$baseUrl$path'));
      request.headers.contentType = ContentType.json;
      if (accessToken != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $accessToken',
        );
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close();
      final rawBody = await response.transform(utf8.decoder).join();
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

  void close() => _client.close(force: true);
}
