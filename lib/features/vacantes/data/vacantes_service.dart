import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';

/// Llama al endpoint público del portal de empleos.
/// Es PÚBLICO: no requiere token ni empresa; el slug identifica a la empresa.
///
/// Ubicación sugerida:  lib/features/vacantes/data/vacantes_service.dart
///
/// Requiere el paquete http. Si no lo tienes:  flutter pub add http
class VacantesService {
  /// Sin barra final. Confirma en /docs si el prefijo es /api/v1 o no.
  final String baseUrl;
  final http.Client _client;

  VacantesService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Future<List<Vacante>> vacantesPublicas(String slug) async {
    // >>> VERIFICA esta ruta en /docs. La tarea dice: /publico/{slug}/vacantes
    final uri = Uri.parse('$baseUrl/publico/$slug/vacantes');

    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      // utf8.decode conserva las tildes correctamente.
      final data = jsonDecode(utf8.decode(res.bodyBytes));

      // El backend puede devolver una lista directa [...] o envolverla en
      // {"items": [...]} o {"data": [...]}. Cubrimos los tres casos.
      final List lista = data is List
          ? data
          : (data['items'] ?? data['data'] ?? const []);

      return lista
          .map((e) => Vacante.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      res.statusCode,
      'No se pudieron cargar las vacantes (código ${res.statusCode}).',
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
