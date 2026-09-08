import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';

class VacantesService {
  // Asegúrate de cambiar esto por la URL real de tu backend (ej. de Railway)
  final String baseUrl;
  final http.Client _client;

  VacantesService({
    required this.baseUrl, 
    http.Client? client
  }) : _client = client ?? http.Client();

  Future<List<Vacante>> vacantesPublicas(String slug) async {
    // Si tu API usa /api/v1, asegúrate de que baseUrl lo incluya
    // Ejemplo: baseUrl = 'https://tu-api.up.railway.app/api/v1'
    final uri = Uri.parse('https://backendssasrrhh-production.up.railway.app');

    try {
      final res = await _client.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));

        // Cubre escenarios de lista directa o paginación/diccionario
        final List lista = data is List
            ? data
            : (data['items'] ?? data['data'] ?? const []);

        return lista
            .map((e) => Vacante.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(
        res.statusCode,
        'Error al cargar las vacantes. Código: ${res.statusCode}',
      );
    } catch (e) {
      // Captura errores de red (ej. sin internet o servidor caído)
      throw ApiException(
        500,
        'Error de conexión: $e',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}