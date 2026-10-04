import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mobile_ssas_rrhh/features/entrevista/model/entrevista.dart';

/// Ver y confirmar la entrevista con el código de seguimiento (T2-19).
/// Es PÚBLICO: no requiere token; el código identifica la postulación,
/// igual que GET /publico/postulaciones/{codigo} (T2-18).
///
/// El código de seguimiento permite consultar y confirmar la entrevista.
class EntrevistaService {
  /// Sin barra final, con el prefijo /api/v1.
  final String baseUrl;
  final http.Client _client;

  EntrevistaService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Future<Map<String, dynamic>> consultarPorCodigo(String codigo) async {
    final response = await _client.get(_ruta(codigo))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw EntrevistaException(response.statusCode,
          response.statusCode == 404 ? 'No hay entrevista disponible para ese código.'
              : 'No se pudo consultar la entrevista.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmarPorCodigo(
      String codigo, String entrevistaId) async {
    final uri = _ruta(codigo, '/confirmar')
        .replace(queryParameters: {'entrevista_id': entrevistaId});
    final response = await _client.post(uri)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw EntrevistaException(response.statusCode,
          response.statusCode == 409 ? 'La entrevista ya no se puede confirmar.'
              : 'No se pudo confirmar la entrevista.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  void close() => _client.close();

  Uri _ruta(String codigo, [String extra = '']) => Uri.parse(
    '$baseUrl/publico/postulaciones/${Uri.encodeComponent(codigo)}'
    '/entrevista$extra',
  );

  /// Devuelve null cuando no hay entrevista que mostrar (404): el código no
  /// existe o la postulación todavía no tiene entrevista programada. Ese
  /// null es el estado "vacío" de la pantalla.
  Future<Entrevista?> porCodigo(String codigo) async {
    // >>> VERIFICA esta ruta en /docs. <<<
    final res = await _client.get(_ruta(codigo));

    if (res.statusCode == 200) return _leer(res);
    if (res.statusCode == 404) return null;

    throw EntrevistaException(
      res.statusCode,
      'No se pudo consultar tu entrevista (código ${res.statusCode}).',
    );
  }

  /// Confirma la asistencia y devuelve la entrevista ya actualizada.
  Future<Entrevista> confirmar(String codigo) async {
    // >>> VERIFICA esta ruta en /docs. <<<
    final res = await _client.post(
      _ruta(codigo, '/confirmar'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );

    if (res.statusCode == 200) return _leer(res);

    // 409: ya estaba confirmada, se canceló o ya pasó la fecha.
    if (res.statusCode == 409) {
      throw EntrevistaException(
        409,
        'Esta entrevista ya no se puede confirmar. '
        'Actualiza la pantalla para ver su estado.',
      );
    }

    throw EntrevistaException(
      res.statusCode,
      'No se pudo confirmar tu asistencia (código ${res.statusCode}).',
    );
  }

  Entrevista _leer(http.Response res) {
    // utf8.decode conserva las tildes correctamente.
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return Entrevista.fromJson(data as Map<String, dynamic>);
  }
}

/// Error al consultar o confirmar la entrevista. Se define aquí, dentro de
/// la feature, igual que SeguimientoException en T2-18.
class EntrevistaException implements Exception {
  final int statusCode;
  final String message;

  EntrevistaException(this.statusCode, this.message);

  @override
  String toString() => message;
}
