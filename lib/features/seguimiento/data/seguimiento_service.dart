import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mobile_ssas_rrhh/features/seguimiento/model/seguimiento_postulacion.dart';

/// Consulta el estado de una postulación con su código de seguimiento (T2-18).
/// Es PÚBLICO: no requiere token ni empresa; el código identifica la postulación.
///
/// >>> VERIFICA contra /docs <<<  Este endpoint TODAVÍA NO EXISTE en el
/// backend. La ruta de abajo es una propuesta del equipo móvil; en cuanto
/// rrhh-api la publique, se ajusta aquí y nada más de la app cambia.
class SeguimientoService {
  /// Sin barra final. Confirma en /docs si el prefijo es /api/v1 o no.
  final String baseUrl;
  final http.Client _client;

  SeguimientoService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Devuelve null cuando el código no existe (404). Ese null es el estado
  /// "vacío" de la pantalla, igual que la lista vacía en T1-18.
  Future<SeguimientoPostulacion?> porCodigo(String codigo) async {
    // >>> VERIFICA esta ruta en /docs. <<<
    final uri = Uri.parse('$baseUrl/publico/postulaciones/$codigo');

    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      // utf8.decode conserva las tildes correctamente.
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return SeguimientoPostulacion.fromJson(data as Map<String, dynamic>);
    }

    // El código no corresponde a ninguna postulación: no es un error de red,
    // es un resultado válido y la pantalla lo muestra como estado vacío.
    if (res.statusCode == 404) return null;

    throw SeguimientoException(
      res.statusCode,
      'No se pudo consultar tu postulación (código ${res.statusCode}).',
    );
  }
}

/// Error al consultar el seguimiento. Se define aquí, dentro de la feature,
/// siguiendo el mismo criterio que PostulacionException en T1-20.
class SeguimientoException implements Exception {
  final int statusCode;
  final String message;

  SeguimientoException(this.statusCode, this.message);

  @override
  String toString() => message;
}
