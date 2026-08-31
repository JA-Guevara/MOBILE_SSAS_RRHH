import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/postulante.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/resultado_postulacion.dart';

/// Registra una postulación en el portal público de empleos (T1-20).
/// Es PÚBLICO: no requiere token ni empresa; el slug identifica a la empresa.
///
/// El envío es multipart porque lleva el CV junto con los datos del
/// postulante en una sola petición.
class PostulacionesService {
  /// Sin barra final. Confirma en /docs si el prefijo es /api/v1 o no.
  final String baseUrl;
  final http.Client _client;

  PostulacionesService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Future<ResultadoPostulacion> postular({
    required String slug,
    required int vacanteId,
    required Postulante postulante,
    required CvAdjunto cv,
  }) async {
    // >>> VERIFICA esta ruta en /docs. <<<
    final uri = Uri.parse(
      '$baseUrl/publico/$slug/vacantes/$vacanteId/postulaciones',
    );

    final req = http.MultipartRequest('POST', uri)
      ..fields.addAll(postulante.toFields())
      ..files.add(
        http.MultipartFile.fromBytes(
          // >>> VERIFICA el nombre de esta parte en /docs ('cv' o 'archivo'). <<<
          'cv',
          cv.bytes,
          filename: cv.nombre,
          contentType: MediaType.parse(cv.mimeType),
        ),
      );

    final res = await http.Response.fromStream(await _client.send(req));

    // utf8.decode conserva las tildes correctamente.
    final cuerpo = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(cuerpo);
      return ResultadoPostulacion.fromJson(data as Map<String, dynamic>);
    }

    throw PostulacionException.desdeRespuesta(res.statusCode, cuerpo);
  }
}

/// Error de la postulación. El backend es la autoridad: si rechaza algún
/// campo (422), [erroresPorCampo] trae el detalle para pintarlo debajo del
/// campo correspondiente del formulario.
class PostulacionException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, String> erroresPorCampo;

  PostulacionException(
    this.statusCode,
    this.message, {
    this.erroresPorCampo = const {},
  });

  /// Traduce la respuesta de error a algo que la pantalla pueda mostrar.
  /// Entiende el formato de FastAPI ({"detail": [{"loc": [...], "msg": ...}]})
  /// y el formato simple ({"detail": "texto"} / {"mensaje": "texto"}).
  factory PostulacionException.desdeRespuesta(int statusCode, String cuerpo) {
    final generico = switch (statusCode) {
      400 || 422 => 'Revisa los datos del formulario.',
      404 => 'La vacante ya no está disponible.',
      413 => 'El archivo es demasiado grande.',
      _ => 'No se pudo enviar la postulación (código $statusCode).',
    };

    if (cuerpo.isEmpty) return PostulacionException(statusCode, generico);

    try {
      final data = jsonDecode(cuerpo);
      if (data is! Map<String, dynamic>) {
        return PostulacionException(statusCode, generico);
      }

      final detalle = data['detail'] ?? data['mensaje'] ?? data['message'];

      if (detalle is String && detalle.isNotEmpty) {
        return PostulacionException(statusCode, detalle);
      }

      if (detalle is List) {
        final porCampo = <String, String>{};
        for (final e in detalle) {
          if (e is! Map) continue;
          final loc = e['loc'];
          // loc es ["body", "email"]: el último elemento es el campo.
          final campo = loc is List && loc.isNotEmpty
              ? loc.last.toString()
              : '';
          final msg = (e['msg'] ?? '').toString();
          if (campo.isNotEmpty && msg.isNotEmpty) porCampo[campo] = msg;
        }
        if (porCampo.isNotEmpty) {
          return PostulacionException(
            statusCode,
            generico,
            erroresPorCampo: porCampo,
          );
        }
      }
    } on FormatException {
      // El backend no devolvió JSON; nos quedamos con el mensaje genérico.
    }

    return PostulacionException(statusCode, generico);
  }

  @override
  String toString() => message;
}
