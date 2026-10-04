import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';

class VacantesService {
  final String baseUrl;
  final http.Client _client;

  VacantesService({
    required this.baseUrl, 
    http.Client? client
  }) : _client = client ?? http.Client();

  Uri _uri(String slug, [String? id]) => Uri.parse(baseUrl).replace(
    pathSegments: [
      ...Uri.parse(baseUrl).pathSegments.where((segment) => segment.isNotEmpty),
      'publico', slug, 'vacantes',
      if (id != null) id,
    ],
  );

  Future<String> nombreEmpresa(String slug) async {
    final uri = Uri.parse(baseUrl).replace(pathSegments: [
      ...Uri.parse(baseUrl).pathSegments.where((segment) => segment.isNotEmpty),
      'publico', slug,
    ]);
    final response = await _get(uri);
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) throw const FormatException('Empresa inválida');
    if (data['portal_publico_activo'] == false) {
      throw ApiException(403, 'El portal de empleos no está disponible.');
    }
    return (data['nombre_comercial'] ?? data['nombre'] ?? slug).toString();
  }

  Future<List<Vacante>> vacantesPublicas(String slug) async {
    final response = await _get(_uri(slug));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) throw const FormatException('Lista de vacantes inválida');
    return data.map((item) => Vacante.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Vacante> obtenerDetalle(String slug, String id) async {
    final response = await _get(_uri(slug, id));
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) throw const FormatException('Vacante inválida');
    return Vacante.fromJson(data);
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(response.statusCode, response.statusCode == 404
            ? 'No se encontró la empresa o la vacante.'
            : 'No se pudieron cargar las vacantes (${response.statusCode}).');
      }
      return response;
    } on ApiException {
      rethrow;
    } on Exception {
      throw ApiException(0, 'No se pudo conectar con el servidor.');
    }
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
