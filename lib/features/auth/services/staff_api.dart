import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class StaffApiException implements Exception {
  final int status;
  final String message;
  const StaffApiException(this.status, this.message);

  @override
  String toString() => message;
}

class StaffApi {
  StaffApi({required this.baseUrl, http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  static const _accessKey = 'staff_access_token';
  static const _refreshKey = 'staff_refresh_token';

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? empresaSlug,
  }) async {
    final body = <String, Object>{
      if (empresaSlug != null && empresaSlug.isNotEmpty) 'empresa_slug': empresaSlug,
      if (identifier.contains('@')) 'email': identifier.trim(),
      if (!identifier.contains('@')) 'username': identifier.trim(),
      'password': password,
    };
    final tokens = await _send('POST', '/auth/login', body: body);
    final pair = tokens as Map<String, dynamic>;
    if (pair['must_change_password'] == true) {
      throw const StaffApiException(403,
          'Debes cambiar tu contraseña desde la web antes de entrar en mobile.');
    }
    await _savePair(pair);
    try {
      return await profile();
    } catch (_) {
      await _clear();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> profile() async =>
      await _authorized('GET', '/auth/me') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> vacancies({String? empresaId}) async {
    final data = await _authorized('GET', '/seleccion/vacantes',
        query: empresaId == null ? null : {'empresa_id': empresaId});
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> ranking(String vacancyId,
          {String order = 'ia', String? empresaId, String? estado,
          int offset = 0, int limit = 20}) async =>
      await _authorized('GET', '/vacantes/$vacancyId/ranking',
          query: {'orden': order, 'offset': '$offset', 'limit': '$limit',
            if (estado != null) 'estado': estado,
            if (empresaId != null) 'empresa_id': empresaId})
          as Map<String, dynamic>;

  Future<void> logout() async {
    try {
      var refresh = await _storage.read(key: _refreshKey);
      if (refresh != null) {
        try {
          await _send('POST', '/auth/logout', body: {'refresh_token': refresh},
              token: await _storage.read(key: _accessKey));
        } on StaffApiException catch (error) {
          if (error.status != 401) rethrow;
          final access = await _refresh();
          refresh = await _storage.read(key: _refreshKey);
          if (refresh != null) {
            await _send('POST', '/auth/logout',
                body: {'refresh_token': refresh}, token: access);
          }
        }
      }
    } finally {
      await _clear();
    }
  }

  Future<Object?> _authorized(String method, String path,
      {Map<String, Object?>? body, Map<String, String>? query}) async {
    var access = await _storage.read(key: _accessKey);
    if (access == null) throw const StaffApiException(401, 'Inicia sesión.');
    try {
      return await _send(method, path, body: body, token: access, query: query);
    } on StaffApiException catch (error) {
      if (error.status != 401) rethrow;
      access = await _refresh();
      return _send(method, path, body: body, token: access, query: query);
    }
  }

  Future<String> _refresh() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) throw const StaffApiException(401, 'La sesión venció.');
    try {
      final tokens = await _send('POST', '/auth/refresh',
          body: {'refresh_token': refresh}) as Map<String, dynamic>;
      await _savePair(tokens);
      return tokens['access_token'] as String;
    } on StaffApiException catch (error) {
      if (error.status == 401) await _clear();
      rethrow;
    }
  }

  Future<void> _savePair(Map<String, dynamic> tokens) async {
    final access = tokens['access_token'];
    final refresh = tokens['refresh_token'];
    if (access is! String || access.isEmpty || refresh is! String || refresh.isEmpty) {
      throw const StaffApiException(502, 'Respuesta de sesión inválida.');
    }
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> _clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<Object?> _send(String method, String path,
      {Map<String, Object?>? body, String? token, Map<String, String>? query}) async {
    final headers = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      if (token != null) 'authorization': 'Bearer $token',
    };
    http.Response response;
    try {
      response = await (method == 'GET'
          ? _client.get(_uri(path, query), headers: headers)
          : _client.post(_uri(path, query), headers: headers,
              body: jsonEncode(body ?? const <String, Object?>{})))
          .timeout(const Duration(seconds: 20));
    } on Exception {
      throw const StaffApiException(0, 'No se pudo conectar con el servidor.');
    }
    Object? data;
    try {
      data = response.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const StaffApiException(502, 'Respuesta inválida del servidor.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      throw StaffApiException(response.statusCode,
          detail is String ? detail : 'Solicitud rechazada (${response.statusCode}).');
    }
    if (data is! Map<String, dynamic> && data is! List) {
      throw const StaffApiException(502, 'Respuesta inválida del servidor.');
    }
    return data;
  }

  void close() => _client.close();
}
