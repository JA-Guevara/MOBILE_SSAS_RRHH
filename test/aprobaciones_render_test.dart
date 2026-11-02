import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/bandeja_page.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/solicitud_detalle_page.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/tarjeta_saldo.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

/// Lienzo alto: ListView.builder solo construye lo que cabe en pantalla.
void _lienzoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  test('el estado se interpreta y lo desconocido no se finge pendiente', () {
    expect(
      SolicitudAusencia.parseEstado('pendiente'),
      EstadoSolicitud.pendiente,
    );
    expect(SolicitudAusencia.parseEstado('APROBADA'), EstadoSolicitud.aprobada);
    expect(
      SolicitudAusencia.parseEstado('rechazado'),
      EstadoSolicitud.rechazada,
    );
    expect(SolicitudAusencia.parseEstado('anulada'), EstadoSolicitud.cancelada);
    expect(SolicitudAusencia.parseEstado('en_revision'), EstadoSolicitud.otro);
    expect(SolicitudAusencia.parseEstado(null), EstadoSolicitud.otro);
  });

  test('el saldo avisa cuando no alcanza', () {
    const saldo = SaldoVacacion(
      id: '1',
      gestion: 2026,
      diasAsignados: 15,
      diasUsados: 12,
      diasSaldo: 3,
    );
    expect(saldo.resumen, '3 de 15 días disponibles');
    expect(saldo.alcanzaPara(3), isTrue);
    expect(saldo.alcanzaPara(5), isFalse);
    // Sin dato de días pedidos no se puede afirmar que falte saldo.
    expect(saldo.alcanzaPara(null), isTrue);

    // Medio día no debe salir como "0.5".
    expect(SaldoVacacion.dias(2.5), '2,5');
    expect(SaldoVacacion.dias(3), '3');
  });

  testWidgets('bandeja: pendientes, la más antigua primero', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(
      _app(BandejaPage(service: AprobacionesServiceFalso())),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Por aprobar'), findsOneWidget);
    expect(
      find.text('3 solicitudes · las que llevan más tiempo esperando, primero'),
      findsOneWidget,
    );

    // Marco pidió el 24, Julia el 25, Renata el 26.
    expect(find.text('Marco Terceros'), findsOneWidget);
    expect(find.text('Julia Quispe'), findsOneWidget);
    expect(find.text('Renata Suárez'), findsOneWidget);

    // Avisos que el jefe debe ver sin entrar al detalle.
    expect(find.text('Falta el documento de respaldo'), findsOneWidget);
    expect(find.text('Supera su saldo: 3 días'), findsOneWidget);
  });

  testWidgets('detalle: enseña el saldo solo si descuenta vacación', (
    tester,
  ) async {
    _lienzoAlto(tester);

    // Julia pide vacación: descuenta_vacacion = true.
    await tester.pumpWidget(
      _app(
        SolicitudDetallePage(
          solicitudId: '41',
          solicitante: 'Julia Quispe',
          service: AprobacionesServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TarjetaSaldo), findsOneWidget);
    expect(find.text('3 de 15 días disponibles'), findsOneWidget);
    expect(find.textContaining('son más de los que tiene'), findsOneWidget);
    expect(find.text('12/09 al 16/09'), findsOneWidget);
    expect(find.text('5 días'), findsOneWidget);
  });

  testWidgets('detalle: sin descuento de vacación no hay saldo', (
    tester,
  ) async {
    _lienzoAlto(tester);

    // Marco pide baja médica: descuenta_vacacion = false.
    await tester.pumpWidget(
      _app(
        SolicitudDetallePage(
          solicitudId: '42',
          solicitante: 'Marco Terceros',
          service: AprobacionesServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TarjetaSaldo), findsNothing);
    // Pero sí avisa de que falta el documento que ese tipo exige.
    expect(find.textContaining('exige documento de respaldo'), findsOneWidget);
  });

  testWidgets('rechazar sin observación no se puede confirmar', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(
      _app(
        SolicitudDetallePage(
          solicitudId: '41',
          solicitante: 'Julia Quispe',
          service: AprobacionesServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();

    // El diálogo de confirmación está abierto.
    expect(find.text('¿Rechazar la solicitud?'), findsOneWidget);

    // Confirmar sin escribir nada: se reclama el motivo y NO se cierra.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('Explica por qué la rechazas.'), findsOneWidget);
    expect(find.text('¿Rechazar la solicitud?'), findsOneWidget);

    // Con motivo sí se ejecuta.
    await tester.enterText(
      find.byType(TextField),
      'No hay cobertura esa semana.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Rechazar la solicitud?'), findsNothing);
    expect(find.textContaining('Solicitud rechazada'), findsWidgets);
    expect(find.text('No hay cobertura esa semana.'), findsOneWidget);
    // Ya respondida: los botones desaparecen.
    expect(find.widgetWithText(OutlinedButton, 'Rechazar'), findsNothing);
  });

  testWidgets('aprobar: la observación es opcional y se confirma', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(
      _app(
        SolicitudDetallePage(
          solicitudId: '43',
          solicitante: 'Renata Suárez',
          service: AprobacionesServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Aprobar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Aprobar la solicitud?'), findsOneWidget);

    // Sin escribir nada: se aprueba igual. Se busca DENTRO del diálogo: el
    // botón de la pantalla, detrás, también es un ElevatedButton "Aprobar".
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Aprobar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¿Aprobar la solicitud?'), findsNothing);
    expect(find.textContaining('Solicitud aprobada'), findsWidgets);
  });

  testWidgets('cancelar el diálogo no ejecuta nada', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(
      _app(
        SolicitudDetallePage(
          solicitudId: '41',
          solicitante: 'Julia Quispe',
          service: AprobacionesServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Aprobar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Sigue pendiente: los dos botones siguen ahí.
    expect(find.widgetWithText(ElevatedButton, 'Aprobar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rechazar'), findsOneWidget);
    expect(find.textContaining('Solicitud aprobada'), findsNothing);
  });

  testWidgets('bandeja vacía', (tester) async {
    await tester.pumpWidget(
      _app(BandejaPage(service: AprobacionesServiceVacio())),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No tienes solicitudes por responder'),
      findsOneWidget,
    );
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(
      _app(BandejaPage(service: AprobacionesServiceError())),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudo completar la operación'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('401: distingue sesión expirada de fallo de red', (tester) async {
    await tester.pumpWidget(
      _app(BandejaPage(service: AprobacionesServiceSinSesion())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
  });
}
