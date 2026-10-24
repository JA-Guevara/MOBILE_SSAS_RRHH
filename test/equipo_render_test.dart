import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/contrato.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/miembro_equipo.dart';
import 'package:mobile_ssas_rrhh/features/equipo/ui/equipo_page.dart';
import 'package:mobile_ssas_rrhh/features/equipo/ui/widgets/miembro_card.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/referencias/referencias.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

/// Una persona con la fila de asistencia [asistencia] (solo columnas de la
/// tabla), o sin fila si es null.
MiembroEquipo _m(Map<String, dynamic>? asistencia) => MiembroEquipo(
  contrato: const Contrato(id: 'c1', empleadoId: 'e1'),
  empleado: const EmpleadoRef(
    id: 'e1',
    nombres: 'Ana',
    apellidoPaterno: 'Rojas',
  ),
  asistencia: asistencia == null ? null : Asistencia.fromJson(asistencia),
);

void main() {
  group('estado del día', () {
    test('los cuatro estados', () {
      expect(_m(null).estadoDia, EstadoDia.sinMarcar);
      expect(_m({'hora_entrada': '08:00:00'}).estadoDia, EstadoDia.enJornada);
      expect(
        _m({'hora_entrada': '08:00:00', 'hora_salida': '17:00:00'}).estadoDia,
        EstadoDia.salio,
      );
      expect(_m({'estado': 'VACACION'}).estadoDia, EstadoDia.ausente);
      expect(
        _m({'estado': 'falta_injustificada'}).estadoDia,
        EstadoDia.ausente,
      );
      // Una marca sin horas y sin estado de ausencia es "sin marcar".
      expect(_m({'hora_entrada': ''}).estadoDia, EstadoDia.sinMarcar);
    });

    test('la línea de detalle de cada estado', () {
      expect(_m(null).detalleDia, 'Todavía no marcó su entrada');
      expect(
        _m({'hora_entrada': '08:12:00', 'minutos_retraso': 12}).detalleDia,
        'Entró 08:12 · 12 min tarde',
      );
      expect(_m({'hora_entrada': '07:56:00'}).detalleDia, 'Entró 07:56');
      expect(
        _m({'hora_entrada': '07:00:00', 'hora_salida': '13:05:00'}).detalleDia,
        '07:00 a 13:05',
      );
      expect(_m({'estado': 'VACACION'}).detalleDia, 'Vacación');
      expect(
        _m({'estado': 'falta_injustificada'}).detalleDia,
        'Falta injustificada',
      );
    });

    test('sin nombre resuelto muestra el número de contrato', () {
      const m = MiembroEquipo(
        contrato: Contrato(id: 'c1', numeroContrato: 'CTR-2026-001'),
      );
      expect(m.nombreCompleto, 'Contrato CTR-2026-001');
      expect(m.iniciales, '?');
    });
  });

  group('contrato del API', () {
    test('Contrato lee las 19 columnas de la tabla', () {
      final c = Contrato.fromJson(EquipoServiceFalso.contratos.first);
      expect(c.id, 'c12');
      expect(c.empleadoId, 'e12');
      expect(c.cargoId, 'g3');
      expect(c.jefeDirectoId, 'e1');
      expect(c.tipoContrato, 'INDEFINIDO');
      expect(c.jornada, 'TIEMPO_COMPLETO');
      expect(c.salarioBasico, 6500);
      expect(c.esVigente, isTrue);
      // Numeric de Postgres como texto.
      expect(
        Contrato.fromJson({'id': 'x', 'salario_basico': '6500.50'})
            .salarioBasico,
        6500.5,
      );
    });

    test('une contrato, empleado, cargo y asistencia por sus llaves', () async {
      final peticiones = <http.Request>[];
      final cliente = MockClient((req) async {
        peticiones.add(req);
        final cuerpo = switch (req.url.path) {
          '/api/v1/contratos/mi-equipo' => [
            {
              'id': 'c2',
              'empleado_id': 'u2',
              'cargo_id': 'g1',
              'estado': 'VIGENTE',
            },
            {
              'id': 'c1',
              'empleado_id': 'u1',
              'cargo_id': 'g1',
              'estado': 'VIGENTE',
            },
            // Contrato cerrado: no debe aparecer.
            {
              'id': 'c0',
              'empleado_id': 'u1',
              'cargo_id': 'g9',
              'estado': 'FINALIZADO',
            },
          ],
          '/api/v1/asistencias' => [
            {'id': 'a1', 'empleado_id': 'u1', 'hora_entrada': '08:00:00'},
          ],
          '/api/v1/empleados' => [
            {'id': 'u1', 'nombres': 'Ana', 'apellido_paterno': 'Ríos'},
            {'id': 'u2', 'nombres': 'Zoe', 'apellido_paterno': 'Paz'},
          ],
          '/api/v1/cargos' => [
            {'id': 'g1', 'nombre': 'Contadora'},
          ],
          _ => throw StateError('ruta inesperada ${req.url}'),
        };
        return http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), 200);
      });
      final storage = MemoryTokenStorage();
      await storage.saveAccessToken('token-jefe');
      final servicio = EquipoService(
        AppHttpClient(baseUrl: 'https://api.test/api/v1', client: cliente),
        storage,
        hoy: () => DateTime(2026, 10, 24, 9, 30),
      );

      final equipo = await servicio.miEquipo();

      expect(
        peticiones.every(
          (r) => r.headers['authorization'] == 'Bearer token-jefe',
        ),
        isTrue,
      );
      final asistencia = peticiones.firstWhere(
        (r) => r.url.path == '/api/v1/asistencias',
      );
      expect(asistencia.url.queryParameters['fecha'], '2026-10-24');

      expect(equipo.map((m) => m.nombreCompleto), ['Ana Ríos', 'Zoe Paz']);
      expect(equipo.map((m) => m.cargoNombre), ['Contadora', 'Contadora']);
      expect(equipo.map((m) => m.estadoDia), [
        EstadoDia.enJornada,
        EstadoDia.sinMarcar,
      ]);
    });
  });

  testWidgets('con datos: resumen del día y lista por nombre', (tester) async {
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(EquipoPage(service: EquipoServiceFalso())));

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Equipo a mi cargo'), findsOneWidget);
    expect(find.text('6 personas a tu cargo'), findsOneWidget);
    expect(
      find.text('Hoy: 3 en jornada · 1 salió · 1 sin marcar · 1 ausente'),
      findsOneWidget,
    );

    final nombres = tester
        .widgetList<MiembroCard>(find.byType(MiembroCard))
        .map((c) => c.miembro.nombreCompleto)
        .toList();
    expect(nombres, [
      'Diego Roca Suárez',
      'Julia Quispe',
      'Lucía Fernández Rojas',
      'Marco Terceros Vaca',
      'Pablo Arias',
      'Rosa Mamani',
    ]);

    // Cargo y estado de cada persona, como pide la tarea.
    expect(find.text('Analista contable'), findsNWidgets(2));
    expect(find.text('Entró 08:12 · 12 min tarde'), findsOneWidget);
    expect(find.text('Todavía no marcó su entrada'), findsOneWidget);
  });

  testWidgets('nadie a cargo: estado vacío', (tester) async {
    await tester.pumpWidget(_app(EquipoPage(service: EquipoServiceVacio())));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no tienes personas a tu cargo'), findsOneWidget);
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_app(EquipoPage(service: EquipoServiceError())));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo cargar tu equipo'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('403: no es jefe, no "sesión expirada"', (tester) async {
    await tester.pumpWidget(
      _app(EquipoPage(service: EquipoServiceSinPermiso())),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Esta vista es solo para jefes directos.'),
      findsOneWidget,
    );
  });
}
