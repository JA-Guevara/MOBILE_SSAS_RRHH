import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service.dart';
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

  test(
    'saldo y equipo usan lecturas propias sin consultar todos los empleados',
    () async {
      final paths = <String>[];
      final client = AppHttpClient(
        baseUrl: 'https://example.test/api/v1',
        client: MockClient((request) async {
          paths.add(request.url.path);
          final data = request.url.path.endsWith('/vacaciones')
              ? [
                  {
                    'id': 'saldo-1',
                    'empleado_id': 'e1',
                    'gestion': 2026,
                    'dias_asignados': 15,
                    'dias_usados': 4,
                    'dias_saldo': 11,
                  },
                ]
              : [
                  {
                    'contrato': {
                      'id': 'c1',
                      'empleado_id': 'e1',
                      'cargo_id': 'cargo-1',
                      'estado': 'VIGENTE',
                    },
                    'empleado': {
                      'id': 'e1',
                      'nombres': 'Ana',
                      'apellido_paterno': 'Lopez',
                    },
                    'cargo': {'id': 'cargo-1', 'nombre': 'Auxiliar'},
                    'asistencia': null,
                  },
                ];
          return http.Response(jsonEncode(data), 200);
        }),
      );
      final token = MemoryTokenStorage()..saveAccessToken('token-prueba');
      expect((await leerSaldoMio(client, 'token-prueba'))?.diasSaldo, 11);
      final equipo = await EquipoService(client, token).miEquipo();
      expect(equipo.single.nombreCompleto, 'Ana Lopez');
      expect(equipo.single.estadoDia.name, 'sinMarcar');
      expect(paths, [
        '/api/v1/personal/mi/vacaciones',
        '/api/v1/personal/mi/equipo/resumen',
      ]);
      client.close();
    },
  );

  test(
    'aprobación usa la solicitud real y envía la decisión del backend',
    () async {
      final requests = <http.Request>[];
      var approved = false;
      final client = AppHttpClient(
        baseUrl: 'https://example.test/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') approved = true;
          final data = request.method == 'POST'
              ? {'id': 's1', 'estado': 'APROBADA'}
              : [
                  {
                    'id': 's1',
                    'empleado_id': 'e1',
                    'tipo_ausencia_id': 't1',
                    'fecha_inicio': '2026-11-02',
                    'fecha_fin': '2026-11-03',
                    'dias_solicitados': 2,
                    'motivo': 'Trámite',
                    'estado': approved ? 'APROBADA' : 'PENDIENTE',
                    'creado_en': '2026-11-01T12:00:00Z',
                    'empleado': {
                      'id': 'e1',
                      'nombres': 'Ana',
                      'apellido_paterno': 'Lopez',
                    },
                    'tipo': {
                      'id': 't1',
                      'nombre': 'Permiso',
                      'descuenta_vacacion': false,
                    },
                    'saldo': null,
                  },
                ];
          return http.Response(
            jsonEncode(data),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final token = MemoryTokenStorage()..saveAccessToken('token-prueba');
      final service = AprobacionesService(client, token);
      expect((await service.pendientes()).single.solicitante, 'Ana Lopez');
      expect((await service.aprobar('s1')).estadoCrudo, 'APROBADA');
      final post = requests.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, '/api/v1/personal/ausencias/s1/decision');
      expect(jsonDecode(post.body), {'aprobar': true});
      client.close();
    },
  );
}
