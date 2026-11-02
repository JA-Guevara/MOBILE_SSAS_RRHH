import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

void main() {
  test('personal usa rutas reales, token y campos GPS del backend', () async {
    final requests = <http.Request>[];
    final httpClient = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      Object response = <String, Object>{};
      if (path.endsWith('/mi/asistencia')) response = <Object>[];
      if (path.endsWith('/mi/asistencia/entrada')) {
        response = {'id': 'marca-1', 'hora_entrada': '2026-11-02T12:00:00Z'};
      }
      if (path.endsWith('/mi/boletas')) response = <Object>[];
      if (path.endsWith('/nomina/periodos')) response = <Object>[];
      if (path.endsWith('/mi/documentos')) response = <Object>[];
      if (path.endsWith('/mi/contratos')) response = <Object>[];
      if (path.endsWith('/cargos')) response = <Object>[];
      return http.Response(
        jsonEncode(response),
        path.endsWith('/entrada') ? 201 : 200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = AppHttpClient(
      baseUrl: 'https://example.test/api/v1',
      client: httpClient,
    );
    final token = MemoryTokenStorage()..saveAccessToken('token-prueba');

    await AsistenciaService(
      client,
      token,
    ).marcarEntrada(latitud: -16.5, longitud: -68.1);
    await BoletasService(client, token).mias();
    await LegajoService(client, token).mios();
    await MiContratoService(client, token).historial();

    expect(
      requests.map((r) => r.url.path),
      containsAll([
        '/api/v1/personal/mi/asistencia/entrada',
        '/api/v1/nomina/mi/boletas',
        '/api/v1/nomina/periodos',
        '/api/v1/personal/mi/documentos',
        '/api/v1/personal/mi/contratos',
      ]),
    );
    expect(
      requests.every(
        (r) => r.headers['authorization'] == 'Bearer token-prueba',
      ),
      isTrue,
    );
    final body = jsonDecode(
      requests.firstWhere((r) => r.url.path.endsWith('/entrada')).body,
    );
    expect(body, {'latitud': -16.5, 'longitud': -68.1});
    client.close();
  });
}
