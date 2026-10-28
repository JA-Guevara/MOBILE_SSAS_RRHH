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
/// postMultipart se añadió para los formularios con adjunto (T3-19).
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

  /// POST multipart/form-data: campos de texto más archivos. Es el formato
  /// que FastAPI espera para un UploadFile, igual que el CV de T1-20.
  ///
  /// El content-type no se pone a mano: MultipartRequest lo arma con su
  /// boundary al enviar.
  Future<Object?> postMultipart(
    String path, {
    required Map<String, String> campos,
    List<http.MultipartFile> archivos = const [],
    String? accessToken,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..fields.addAll(campos)
        ..files.addAll(archivos);
      if (accessToken != null) {
        request.headers['authorization'] = 'Bearer $accessToken';
      }

      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      return _leer(response);
    } on AppException {
      rethrow;
    } on Object {
      throw const AppException('No se pudo conectar con el servidor.');
    }
  }

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

      return _leer(response);
    } on AppException {
      rethrow;
    } on Object {
      throw const AppException('No se pudo conectar con el servidor.');
    }
  }

  /// Decodifica la respuesta o lanza AppException con el detail del backend.
  Object? _leer(http.Response response) {
    // Se decodifica en UTF-8 a mano: response.body usa latin1 cuando el
    // servidor no manda charset, y ahí se rompen las tildes y las ñ.
    final rawBody = utf8.decode(response.bodyBytes);
    final data = rawBody.isEmpty ? null : jsonDecode(rawBody);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppException(
        _mensajeDeError(data),
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  /// El detail de FastAPI puede ser un texto o, en un 422 de validación,
  /// una lista de {"loc", "msg"}. Con la lista se juntan los msg: su
  /// toString() mostraría la estructura cruda al usuario.
  static String _mensajeDeError(Object? data) {
    const generico = 'La solicitud no pudo completarse.';
    if (data is! Map<String, dynamic>) return generico;

    final detalle = data['detail'];
    if (detalle is List) {
      final mensajes = detalle
          .whereType<Map<String, dynamic>>()
          .map((e) => e['msg']?.toString() ?? '')
          .where((m) => m.isNotEmpty);
      return mensajes.isEmpty ? generico : mensajes.join('\n');
    }
    return detalle?.toString() ?? generico;
  }

  void close() => _client.close();
}
