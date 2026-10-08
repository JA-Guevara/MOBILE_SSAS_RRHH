import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_ssas_rrhh/features/reportes/report_config.dart';

class StaffApiException implements Exception {
  final int status;
  final String message;
  const StaffApiException(this.status, this.message);

  @override
  String toString() => message;
}

class StaffApi {
  StaffApi({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _client = client ?? http.Client(),
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
      if (empresaSlug != null && empresaSlug.isNotEmpty)
        'empresa_slug': empresaSlug,
      if (identifier.contains('@')) 'email': identifier.trim(),
      if (!identifier.contains('@')) 'username': identifier.trim(),
      'password': password,
    };
    final tokens = await _send('POST', '/auth/login', body: body);
    final pair = tokens as Map<String, dynamic>;
    if (pair['must_change_password'] == true) {
      throw const StaffApiException(
        403,
        'Debes cambiar tu contraseña desde la web antes de entrar en mobile.',
      );
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

  Future<List<String>> chatbotSuggestions() async =>
      (await _authorized('GET', '/chatbot/sugerencias') as List).cast<String>();

  Future<Map<String, dynamic>> askChatbot(String question) async =>
      await _authorized(
        'POST',
        '/chatbot/mensajes',
        body: {'pregunta': question},
      ) as Map<String, dynamic>;

  Future<Map<String, dynamic>> readChatbotArticle(String id) async =>
      await _authorized('GET', '/chatbot/articulos/$id')
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> subscription() async =>
      await _authorized('GET', '/suscripcion') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> subscriptionPlans() async =>
      (await _authorized('GET', '/planes') as List)
          .cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> subscriptionConsumption() async =>
      await _authorized('GET', '/suscripcion/consumo') as Map<String, dynamic>;

  Future<String> createSubscriptionCheckout(String planId) async {
    final result = await _authorized(
      'POST',
      '/suscripcion/checkout',
      body: {'plan_id': planId},
    ) as Map<String, dynamic>;
    return result['url'] as String;
  }

  Future<String> createSubscriptionPortal() async {
    final result = await _authorized(
      'POST',
      '/suscripcion/portal',
    ) as Map<String, dynamic>;
    return result['url'] as String;
  }

  Future<List<Map<String, dynamic>>> applicants({
    int offset = 0,
    int limit = 50,
  }) async => (await _authorized(
    'GET',
    '/postulantes',
    query: {'offset': '$offset', 'limit': '$limit'},
  ) as List).cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> latestTenantBackup() async =>
      await _authorized('GET', '/respaldos-empresa/ultimo')
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> createTenantBackup() async =>
      await _authorized('POST', '/respaldos-empresa', body: {})
          as Map<String, dynamic>;

  Map<String, String>? _reportScope(String? empresaId) =>
      empresaId == null ? null : {'empresa_id': empresaId};

  Future<List<Map<String, dynamic>>> reportCatalog() async =>
      (await _authorized('GET', '/reportes/catalogo') as List)
          .cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> savedReports({String? empresaId}) async =>
      (await _authorized(
        'GET',
        '/reportes',
        query: _reportScope(empresaId),
      ) as List).cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> interpretReport(
    String text, {
    String? empresaId,
  }) async => await _authorized(
    'POST',
    '/reportes/interpretar',
    query: _reportScope(empresaId),
    body: {'texto': text},
  ) as Map<String, dynamic>;

  Future<Map<String, dynamic>> previewReport(
    ReportConfig config, {
    String? empresaId,
    int page = 1,
    int perPage = 25,
  }) async => await _authorized(
    'POST',
    '/reportes/vista-previa',
    query: {
      ...?_reportScope(empresaId),
      'page': '$page',
      'per_page': '$perPage',
    },
    body: config.toJson(),
  ) as Map<String, dynamic>;

  Future<Map<String, dynamic>> createReport(
    String name,
    ReportConfig config, {
    String? empresaId,
  }) async => await _authorized(
    'POST',
    '/reportes',
    query: _reportScope(empresaId),
    body: {'nombre': name, ...config.toJson()},
  ) as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateReport(
    String id,
    String name,
    ReportConfig config, {
    String? empresaId,
  }) async => await _authorized(
    'PATCH',
    '/reportes/$id',
    query: _reportScope(empresaId),
    body: {
      'nombre': name,
      'columnas': config.columns,
      'filtros': config.filters.map((item) => item.toJson()).toList(),
      'orden': config.order.map((item) => item.toJson()).toList(),
    },
  ) as Map<String, dynamic>;

  Future<Uint8List> exportReport(
    String format,
    ReportConfig config, {
    String? empresaId,
  }) async {
    Future<Uint8List> send(String token) async {
      http.Response response;
      try {
        response = await _client
            .post(
              _uri('/reportes/exportar/$format', _reportScope(empresaId)),
              headers: {
                'content-type': 'application/json; charset=utf-8',
                'authorization': 'Bearer $token',
              },
              body: jsonEncode(config.toJson()),
            )
            .timeout(const Duration(seconds: 60));
      } on Exception {
        throw const StaffApiException(0, 'No se pudo descargar el reporte.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? detail;
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map<String, dynamic> && data['detail'] is String) {
            detail = data['detail'] as String;
          }
        } on FormatException {
          // A failed binary request may not include a JSON error body.
        }
        throw StaffApiException(
          response.statusCode,
          detail ?? 'No se pudo exportar (${response.statusCode}).',
        );
      }
      return response.bodyBytes;
    }

    var token = await _storage.read(key: _accessKey);
    if (token == null) throw const StaffApiException(401, 'Inicia sesión.');
    try {
      return await send(token);
    } on StaffApiException catch (error) {
      if (error.status != 401) rethrow;
      token = await _refresh();
      return send(token);
    }
  }

  Future<List<Map<String, dynamic>>> vacancies({String? empresaId}) async {
    final data = await _authorized(
      'GET',
      '/seleccion/vacantes',
      query: empresaId == null ? null : {'empresa_id': empresaId},
    );
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> ranking(
    String vacancyId, {
    String order = 'ia',
    String? empresaId,
    String? estado,
    int offset = 0,
    int limit = 20,
  }) async => await _authorized(
    'GET',
    '/vacantes/$vacancyId/ranking',
    query: {
      'orden': order,
      'offset': '$offset',
      'limit': '$limit',
      'estado': ?estado,
      'empresa_id': ?empresaId,
    },
  ) as Map<String, dynamic>;

  Future<void> logout() async {
    try {
      var refresh = await _storage.read(key: _refreshKey);
      if (refresh != null) {
        try {
          await _send(
            'POST',
            '/auth/logout',
            body: {'refresh_token': refresh},
            token: await _storage.read(key: _accessKey),
          );
        } on StaffApiException catch (error) {
          if (error.status != 401) rethrow;
          final access = await _refresh();
          refresh = await _storage.read(key: _refreshKey);
          if (refresh != null) {
            await _send(
              'POST',
              '/auth/logout',
              body: {'refresh_token': refresh},
              token: access,
            );
          }
        }
      }
    } finally {
      await _clear();
    }
  }

  Future<Object?> _authorized(
    String method,
    String path, {
    Map<String, Object?>? body,
    Map<String, String>? query,
  }) async {
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
    if (refresh == null) {
      throw const StaffApiException(401, 'La sesión venció.');
    }
    try {
      final tokens = await _send(
        'POST',
        '/auth/refresh',
        body: {'refresh_token': refresh},
      ) as Map<String, dynamic>;
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
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const StaffApiException(502, 'Respuesta de sesión inválida.');
    }
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> _clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? token,
    Map<String, String>? query,
  }) async {
    final headers = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      if (token != null) 'authorization': 'Bearer $token',
    };
    http.Response response;
    try {
      final uri = _uri(path, query);
      final request = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'PATCH' => _client.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const <String, Object?>{}),
        ),
        _ => _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const <String, Object?>{}),
        ),
      };
      response = await request.timeout(
        Duration(
          seconds:
              path.startsWith('/chatbot/') || path == '/reportes/interpretar'
              ? 60
              : 20,
        ),
      );
    } on Exception {
      throw const StaffApiException(0, 'No se pudo conectar con el servidor.');
    }
    Object? data;
    try {
      data = response.bodyBytes.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const StaffApiException(502, 'Respuesta inválida del servidor.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      throw StaffApiException(
        response.statusCode,
        detail is String
            ? detail
            : 'Solicitud rechazada (${response.statusCode}).',
      );
    }
    if (data is! Map<String, dynamic> && data is! List) {
      throw const StaffApiException(502, 'Respuesta inválida del servidor.');
    }
    return data;
  }

  void close() => _client.close();
}
