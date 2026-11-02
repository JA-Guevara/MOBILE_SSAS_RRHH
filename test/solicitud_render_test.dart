import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/documento_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/nueva_solicitud.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/solicitar_ausencia_page.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/widgets/campo_fecha.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// "Hoy" en las pruebas: lunes 2 de noviembre de 2026. Así el calendario
/// abre siempre en el mismo mes y los días hábiles no dependen del día en
/// que se corre la prueba.
final _hoy = DateTime(2026, 11, 2);

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

Widget _pagina(SolicitudesService servicio) =>
    _app(SolicitarAusenciaPage(service: servicio, reloj: () => _hoy));

/// Lienzo alto: el formulario entero cabe sin hacer scroll.
void _lienzoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _elegirTipo(WidgetTester tester, String nombre) async {
  await tester.tap(find.byType(DropdownButtonFormField<TipoAusencia>));
  await tester.pumpAndSettle();
  // .last: el elegido también se pinta en el campo, debajo del menú.
  await tester.tap(find.text(nombre).last);
  await tester.pumpAndSettle();
}

/// Elige "Desde" y "Hasta" en el calendario de noviembre de 2026.
Future<void> _elegirFechas(WidgetTester tester, int desde, int hasta) async {
  for (final (campo, dia) in [('Desde', desde), ('Hasta', hasta)]) {
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CampoFecha, campo),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('$dia'));
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
  }
}

Future<void> _escribirMotivo(WidgetTester tester, String motivo) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Cuéntale a tu jefe por qué la pides.'),
    motivo,
  );
  await tester.pump();
}

Future<void> _enviar(WidgetTester tester) async {
  await tester.tap(find.text('Enviar solicitud'));
  await tester.pumpAndSettle();
}

void main() {
  group('días hábiles y reglas del envío', () {
    test('cuenta de lunes a viernes, con las dos puntas', () {
      // 2/11/2026 es lunes.
      expect(NuevaSolicitud.diasHabiles(_hoy, DateTime(2026, 11, 6)), 5);
      expect(NuevaSolicitud.diasHabiles(_hoy, _hoy), 1);
      // Viernes a lunes: el fin de semana no cuenta.
      expect(
        NuevaSolicitud.diasHabiles(
          DateTime(2026, 11, 6),
          DateTime(2026, 11, 9),
        ),
        2,
      );
      expect(
        NuevaSolicitud.diasHabiles(
          DateTime(2026, 11, 7),
          DateTime(2026, 11, 8),
        ),
        0,
      );
      // Fin antes que inicio: no hay días.
      expect(NuevaSolicitud.diasHabiles(DateTime(2026, 11, 6), _hoy), 0);
    });

    test('el saldo y el tope anual impiden enviar', () {
      const vacacion = TipoAusencia(
        id: 't1',
        nombre: 'Vacación',
        descuentaVacacion: true,
        diasMaximosAnio: 15,
      );
      const saldo = SaldoVacacion(id: 's', diasSaldo: 3);

      expect(
        NuevaSolicitud.problemaConLosDias(
          tipo: vacacion,
          dias: 3,
          saldo: saldo,
        ),
        isNull,
      );
      expect(
        NuevaSolicitud.problemaConLosDias(
          tipo: vacacion,
          dias: 5,
          saldo: saldo,
        ),
        'Saldo insuficiente: pides 5 días hábiles y tienes 3 disponibles.',
      );
      expect(
        NuevaSolicitud.problemaConLosDias(tipo: vacacion, dias: 2, saldo: null),
        startsWith('No tienes saldo de vacaciones'),
      );
      expect(
        NuevaSolicitud.problemaConLosDias(
          tipo: vacacion,
          dias: 16,
          saldo: const SaldoVacacion(id: 's', diasSaldo: 30),
        ),
        'Vacación permite hasta 15 días al año.',
      );
      // Un tipo que no descuenta vacación no mira el saldo.
      expect(
        NuevaSolicitud.problemaConLosDias(
          tipo: const TipoAusencia(id: 't2', nombre: 'Baja médica'),
          dias: 10,
          saldo: saldo,
        ),
        isNull,
      );
    });
  });

  testWidgets('muestra el saldo antes de enviar y solo los tipos activos', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceFalso()));

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Solicitar permiso o vacaciones'), findsOneWidget);
    // El saldo de la gestión más reciente (2026), no el de 2025.
    expect(find.text('Saldo de vacaciones · gestión 2026'), findsOneWidget);
    expect(find.text('3 de 15 días disponibles'), findsOneWidget);
    expect(find.text('Elige las fechas'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<TipoAusencia>));
    await tester.pumpAndSettle();
    expect(find.text('Vacación'), findsWidgets);
    expect(find.text('Baja médica'), findsWidgets);
    expect(find.text('Permiso personal'), findsWidgets);
    expect(find.text('Licencia por estudios'), findsNothing);
  });

  testWidgets('enviar vacío: avisa en cada campo', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceFalso()));
    await tester.pumpAndSettle();

    await _enviar(tester);

    expect(find.text('Elige el tipo de ausencia.'), findsOneWidget);
    expect(find.text('Elige la fecha de inicio.'), findsOneWidget);
    expect(find.text('Elige la fecha de fin.'), findsOneWidget);
    expect(find.text('Escribe el motivo de la solicitud.'), findsOneWidget);
    expect(find.text('Solicitud enviada'), findsNothing);
  });

  testWidgets('vacación dentro del saldo: se envía y queda pendiente', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceFalso()));
    await tester.pumpAndSettle();

    await _elegirTipo(tester, 'Vacación');
    expect(find.text('Descuenta de tus vacaciones'), findsOneWidget);

    await _elegirFechas(tester, 2, 3);
    expect(find.text('02/11/2026'), findsOneWidget);
    expect(find.text('03/11/2026'), findsOneWidget);
    // Los días se calculan solos y avisa cuánto le quedará.
    expect(find.text('2 días hábiles'), findsOneWidget);
    expect(
      find.text('Si tu jefe la aprueba, te quedará 1 día de vacación.'),
      findsOneWidget,
    );

    await _escribirMotivo(tester, 'Viaje familiar.');
    await _enviar(tester);

    expect(find.text('Solicitud enviada'), findsOneWidget);
    expect(find.text('Pendiente de aprobación'), findsOneWidget);
    expect(find.text('02/11 al 03/11'), findsOneWidget);
    expect(find.text('2 días hábiles'), findsOneWidget);

    // "Hacer otra solicitud" vuelve al formulario vacío.
    await tester.tap(find.text('Hacer otra solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar solicitud'), findsOneWidget);
    expect(find.text('Elige las fechas'), findsOneWidget);
  });

  testWidgets('saldo insuficiente: avisa y no envía', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceFalso()));
    await tester.pumpAndSettle();

    await _elegirTipo(tester, 'Vacación');
    await _elegirFechas(tester, 2, 6);
    expect(find.text('5 días hábiles'), findsOneWidget);
    expect(
      find.text(
        'Saldo insuficiente: pides 5 días hábiles y tienes 3 disponibles.',
      ),
      findsOneWidget,
    );

    await _escribirMotivo(tester, 'Viaje familiar.');
    await _enviar(tester);

    // Se frenó en el teléfono: ni se envió ni llegó el 422 del backend.
    expect(find.text('Solicitud enviada'), findsNothing);
    expect(find.textContaining('tienes 3 días y pides 5'), findsNothing);
  });

  testWidgets('el tipo exige documento: aparece el adjunto y es obligatorio', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceFalso()));
    await tester.pumpAndSettle();

    // Vacación no pide documento.
    await _elegirTipo(tester, 'Vacación');
    expect(find.text('Adjuntar documento'), findsNothing);

    await _elegirTipo(tester, 'Baja médica');
    expect(find.text('Requiere documento'), findsOneWidget);
    expect(find.text('Adjuntar documento'), findsOneWidget);

    await _elegirFechas(tester, 2, 2);
    expect(find.text('1 día hábil'), findsOneWidget);
    await _escribirMotivo(tester, 'Reposo indicado por el médico.');
    await _enviar(tester);

    expect(
      find.text('Este tipo de ausencia exige un documento de respaldo.'),
      findsOneWidget,
    );
    expect(find.text('Solicitud enviada'), findsNothing);
  });

  testWidgets('fechas en fin de semana: no hay días hábiles', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceFalso()));
    await tester.pumpAndSettle();

    await _elegirTipo(tester, 'Permiso personal');
    await _elegirFechas(tester, 7, 8);

    expect(
      find.text(
        'Las fechas elegidas no tienen días hábiles (de lunes a viernes).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('error al enviar: aviso rojo y el formulario no se pierde', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceErrorAlEnviar()));
    await tester.pumpAndSettle();

    await _elegirTipo(tester, 'Vacación');
    await _elegirFechas(tester, 2, 3);
    await _escribirMotivo(tester, 'Viaje familiar.');
    await _enviar(tester);

    expect(
      find.textContaining('No se pudo enviar la solicitud'),
      findsOneWidget,
    );
    expect(find.text('Viaje familiar.'), findsOneWidget);
    expect(find.text('2 días hábiles'), findsOneWidget);
    expect(find.text('Enviar solicitud'), findsOneWidget);
  });

  testWidgets('sin saldo asignado: avisa y deja pedir otros tipos', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(SolicitudesServiceSinSaldo()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Todavía no tienes saldo de vacaciones'),
      findsOneWidget,
    );
    expect(find.text('Enviar solicitud'), findsOneWidget);
  });

  testWidgets('sin tipos de ausencia: estado vacío', (tester) async {
    await tester.pumpWidget(_pagina(SolicitudesServiceVacio()));
    await tester.pumpAndSettle();

    expect(
      find.text('Tu empresa todavía no configuró tipos de ausencia'),
      findsOneWidget,
    );
  });

  testWidgets('error de red al cargar: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_pagina(SolicitudesServiceError()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudieron cargar los tipos de ausencia'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('401: distingue sesión expirada de fallo de red', (tester) async {
    await tester.pumpWidget(_pagina(SolicitudesServiceSinSesion()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
  });

  group('servicio', () {
    test('carga sin empleado_id: el backend usa el token', () async {
      final peticiones = <PeticionFalsa>[];
      final servicio = SolicitudesService(
        clienteFalso((p) {
          peticiones.add(p);
          return const <Object>[];
        }, demora: Duration.zero),
        sesionFalsa(),
      );

      await servicio.opciones();

      expect(peticiones.map((p) => p.ruta), [
        '/tipos-ausencia',
        '/saldos-vacacion/mio',
      ]);
      expect(peticiones.every((p) => p.query.isEmpty), isTrue);
    });

    test('el saldo puede llegar como una sola fila', () async {
      final servicio = SolicitudesService(
        clienteFalso(
          (p) => p.ruta == '/saldos-vacacion/mio'
              ? {
                  'id': 's1',
                  'gestion': 2026,
                  'dias_asignados': 15,
                  'dias_saldo': 9,
                }
              : const <Object>[],
          demora: Duration.zero,
        ),
        sesionFalsa(),
      );

      final opciones = await servicio.opciones();

      expect(opciones.saldo?.resumen, '9 de 15 días disponibles');
    });

    test(
      'envía multipart con los campos y el documento, sin empleado_id',
      () async {
        PeticionFalsa? recibida;
        final servicio = SolicitudesService(
          clienteFalso((p) {
            recibida = p;
            return {'id': 'n1', 'estado': 'PENDIENTE', 'dias_solicitados': 1};
          }, demora: Duration.zero),
          sesionFalsa(),
        );

        final creada = await servicio.enviar(
          NuevaSolicitud(
            tipo: const TipoAusencia(
              id: 't2',
              nombre: 'Baja médica',
              requiereDocumento: true,
            ),
            fechaInicio: _hoy,
            fechaFin: _hoy,
            motivo: '  Reposo médico.  ',
            documento: DocumentoAdjunto(
              nombre: 'certificado.pdf',
              bytes: Uint8List.fromList([37, 80, 68, 70]),
            ),
          ),
        );

        expect(recibida!.metodo, 'POST');
        expect(recibida!.ruta, '/solicitudes-ausencia');
        expect(recibida!.campos, {
          'tipo_ausencia_id': 't2',
          'fecha_inicio': '2026-11-02',
          'fecha_fin': '2026-11-02',
          'dias_solicitados': '1',
          'motivo': 'Reposo médico.',
        });
        expect(recibida!.archivos['documento']?.nombre, 'certificado.pdf');
        expect(recibida!.archivos['documento']?.bytes, 4);
        expect(creada.estaPendiente, isTrue);
        expect(creada.tipo?.nombre, 'Baja médica');
      },
    );

    test('un 422 con la lista de FastAPI se lee como texto', () async {
      final cliente = AppHttpClient(
        baseUrl: 'https://api.test/api/v1',
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'detail': [
                  {
                    'loc': ['body', 'motivo'],
                    'msg': 'El motivo es obligatorio',
                  },
                ],
              }),
            ),
            422,
          ),
        ),
      );

      await expectLater(
        cliente.postMultipart('/solicitudes-ausencia', campos: const {}),
        throwsA(
          isA<AppException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'El motivo es obligatorio'),
        ),
      );
    });
  });
}
