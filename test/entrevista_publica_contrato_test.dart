import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service.dart';

void main() {
  test('CU-15 consulta y confirma con código de seguimiento', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      expect(request.method,
          request.url.path.endsWith('/confirmar') ? 'POST' : 'GET');
      if (request.url.path.endsWith('/confirmar')) {
        expect(request.url.queryParameters['entrevista_id'],
            '00000000-0000-0000-0000-000000000001');
      }
      return http.Response.bytes(utf8.encode(jsonEncode({
        'id': '00000000-0000-0000-0000-000000000001',
        'estado': request.url.path.endsWith('/confirmar')
            ? 'CONFIRMADA' : 'PROGRAMADA',
        'modalidad': 'VIRTUAL', 'fecha_hora': '2026-10-05T15:00:00Z',
        'duracion_min': 45,
      })), 200);
    });
    final service = EntrevistaService(baseUrl: 'https://example.test/api/v1',
        client: client);
    final item = await service.consultarPorCodigo('POST-A1B2C3D4');
    expect(item['estado'], 'PROGRAMADA');
    final confirmed = await service.confirmarPorCodigo(
        'POST-A1B2C3D4', item['id'] as String);
    expect(confirmed['estado'], 'CONFIRMADA');
    expect(paths, [
      '/api/v1/publico/postulaciones/POST-A1B2C3D4/entrevista',
      '/api/v1/publico/postulaciones/POST-A1B2C3D4/entrevista/confirmar',
    ]);
    service.close();
  });
}
