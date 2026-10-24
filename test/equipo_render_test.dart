import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/miembro_equipo.dart';
import 'package:mobile_ssas_rrhh/features/equipo/ui/equipo_page.dart';
import 'package:mobile_ssas_rrhh/features/equipo/ui/widgets/miembro_card.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

MiembroEquipo _m(Map<String, dynamic>? asistencia) => MiembroEquipo.fromJson({
  'empleado': {'id': 'e1', 'nombres': 'Ana', 'apellido_paterno': 'Rojas'},
  'asistencia': asistencia,
});

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
  });

  group('contrato del API', () {
    test('empleado plano o anidado, cargo como objeto o texto', () {
      final anidado = MiembroEquipo.fromJson({
        'empleado': {
          'id': '9b1c7e52-5f3a-4c1d-8e2b-1d0f6a7c3e90',
          'nombres': 'Lucía',
          'apellido_paterno': 'Fernández',
          'apellido_materno': 'Rojas',
        },
        'cargo': {'id': 'c2', 'nombre': 'Asistente de RR. HH.'},
      });
      expect(anidado.id, '9b1c7e52-5f3a-4c1d-8e2b-1d0f6a7c3e90');
      expect(anidado.nombreCompleto, 'Lucía Fernández Rojas');
      expect(anidado.iniciales, 'LF');
      expect(anidado.cargo, 'Asistente de RR. HH.');

      final plano = MiembroEquipo.fromJson({
        'empleado_id': 'e15',
        'nombres': 'Rosa',
        'apellido_paterno': 'Mamani',
        'cargo': 'Auxiliar contable',
      });
      expect(plano.id, 'e15');
      expect(plano.nombreCompleto, 'Rosa Mamani');
      expect(plano.cargo, 'Auxiliar contable');
    });

    test(
      'pide /empleados/me/equipo con el token y ordena por nombre',
      () async {
        final peticiones = <http.Request>[];
        final cliente = MockClient((req) async {
          peticiones.add(req);
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'items': [
                  {
                    'empleado': {
                      'id': 'u2',
                      'nombres': 'Zoe',
                      'apellido_paterno': 'Paz',
                    },
                  },
                  {
                    'empleado': {
                      'id': 'u1',
                      'nombres': 'Ana',
                      'apellido_paterno': 'Ríos',
                    },
                  },
                ],
              }),
            ),
            200,
          );
        });
        final storage = MemoryTokenStorage();
        await storage.saveAccessToken('token-jefe');
        final servicio = EquipoService(
          AppHttpClient(baseUrl: 'https://api.test/api/v1', client: cliente),
          storage,
        );

        final equipo = await servicio.miEquipo();

        expect(peticiones.single.url.path, '/api/v1/empleados/me/equipo');
        expect(peticiones.single.headers['authorization'], 'Bearer token-jefe');
        expect(equipo.map((m) => m.nombreCompleto), ['Ana Ríos', 'Zoe Paz']);
      },
    );
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
