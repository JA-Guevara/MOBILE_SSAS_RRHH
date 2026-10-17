import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';

class VacantesService {
  /// Con el prefijo /api/v1 y sin barra final.
  /// Ejemplo: 'https://backendssasrrhh-production.up.railway.app/api/v1'
  final String baseUrl;
  final http.Client _client;

  VacantesService({
    required this.baseUrl,
    http.Client? client
  }) : _client = client ?? http.Client();

  /// GET /publico/{slug}: nombre comercial de la empresa del portal.
  Future<String> nombreEmpresa(String slug) async {
    final data = await _get('/publico/$slug', 'la empresa');
    final mapa = data as Map<String, dynamic>;
    return (mapa['nombre_comercial'] ?? mapa['nombre'] ?? slug).toString();
  }

  /// GET /publico/{slug}/vacantes: vacantes publicadas y vigentes.
  Future<List<Vacante>> vacantesPublicas(String slug) async {
    final data = await _get('/publico/$slug/vacantes', 'las vacantes');

    // Cubre escenarios de lista directa o paginación/diccionario
    final List lista = data is List
        ? data
        : (data['items'] ?? data['data'] ?? const []);

    return lista
        .map((e) => Vacante.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /publico/{slug}/vacantes/{id}: detalle de una vacante (T1-19).
  Future<Vacante> vacantePublica(String slug, String vacanteId) async {
    final data = await _get('/publico/$slug/vacantes/$vacanteId', 'la vacante');
    return Vacante.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _get(String ruta, String que) async {
    final http.Response res;
    try {
      res = await _client.get(Uri.parse('$baseUrl$ruta'));
    } catch (e) {
      // Errores de red (ej. sin internet o servidor caído)
      throw ApiException(500, 'Error de conexión: $e');
    }

    if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 404) {
      throw ApiException(404, 'No se encontró $que. Revisa el código de la empresa.');
    }
    throw ApiException(
      res.statusCode,
      'Error al cargar $que. Código: ${res.statusCode}',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
