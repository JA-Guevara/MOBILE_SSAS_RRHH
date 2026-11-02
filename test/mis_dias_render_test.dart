import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/mis_dias/data/mis_dias_service.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/data/mis_dias_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/model/mes_trabajado.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/ui/mis_dias_page.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/ui/widgets/dia_trabajado_card.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// "Hoy" en las pruebas: miércoles 28 de octubre de 2026.
///
/// Con las reglas de MisDiasServiceFalso, octubre hasta el 28 queda así:
///   19 días con marca (20 hábiles menos el 15, de vacación)
///   17 cerrados: 16 de 8 h y el 5, de 9.5 h  -> 137.5 h, 1.5 h extra
///   retrasos: 7, 14 y 21 (12 min), 20 (10) y hoy (5) -> 5 días, 51 min
///   el 20 sin salida; hoy (28) en jornada
final _hoy = DateTime(2026, 10, 28, 10, 30);

Widget _pagina(MisDiasService servicio) => MaterialApp(
  theme: AppTheme.light,
  home: MisDiasPage(service: servicio, reloj: () => _hoy),
);

/// Lienzo alto: así se construyen todas las tarjetas del mes.
void _lienzoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  test('formatos: horas, mes y día', () {
    expect(MesTrabajado.horas(9.15), '9.15 h');
    expect(MesTrabajado.horas(137.5), '137.5 h');
    expect(MesTrabajado.horas(8), '8 h');
    expect(MesTrabajado.horas(0), '0 h');
    expect(MesTrabajado.etiquetaMes(DateTime(2026, 10)), 'Octubre 2026');
    expect(MesTrabajado.parametroMes(DateTime(2026, 9)), '2026-09');
    expect(MesTrabajado.etiquetaDia(DateTime(2026, 10, 28)), 'Mié 28/10');
  });

  testWidgets('el mes actual: saldo, resumen y días', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(MisDiasServiceFalso(reloj: () => _hoy)));

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Mis días trabajados'), findsOneWidget);
    expect(find.text('Octubre 2026'), findsOneWidget);

    // El saldo de vacaciones, el mismo de T3-19.
    expect(find.text('3 de 15 días disponibles'), findsOneWidget);

    // El resumen del mes.
    expect(find.text('19'), findsOneWidget);
    expect(find.text('días trabajados'), findsOneWidget);
    expect(find.text('137.5 h'), findsOneWidget);
    expect(find.text('1.5 h'), findsOneWidget);
    expect(find.text('5 días con retraso · 51 min en total'), findsOneWidget);
    expect(
      find.text(
        '1 día sin marca de salida. Avisa a Recursos Humanos para corregirlo.',
      ),
      findsOneWidget,
    );

    // Un día por tarjeta, el más reciente arriba.
    final dias = tester
        .widgetList<DiaTrabajadoCard>(find.byType(DiaTrabajadoCard))
        .toList();
    expect(dias, hasLength(19));
    expect(dias.first.dia.fecha, DateTime(2026, 10, 28));
    expect(dias.last.dia.fecha, DateTime(2026, 10, 1));

    // Hoy sigue abierto; el 20 se quedó sin salida; el 15 no aparece.
    expect(find.text('Mié 28/10'), findsOneWidget);
    expect(find.text('En jornada'), findsOneWidget);
    expect(find.text('Sin salida'), findsOneWidget);
    expect(find.text('Jue 15/10'), findsNothing);

    // El 5 tuvo horas extra; el 7 llegó tarde.
    expect(find.text('+1.5 h extra'), findsOneWidget);
    expect(find.text('12 min tarde'), findsNWidgets(3));
  });

  testWidgets('se puede ir al mes anterior, pero no al futuro', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(MisDiasServiceFalso(reloj: () => _hoy)));
    await tester.pumpAndSettle();

    IconButton siguiente() => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(siguiente().onPressed, isNull);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();

    // Septiembre entero: 22 hábiles menos el 15 = 21 días, todos cerrados.
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('172.5 h'), findsOneWidget);
    expect(find.text('4.5 h'), findsOneWidget);
    expect(find.text('4 días con retraso · 48 min en total'), findsOneWidget);
    expect(find.text('Sin salida'), findsNothing);
    expect(find.text('En jornada'), findsNothing);
    expect(siguiente().onPressed, isNotNull);

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Octubre 2026'), findsOneWidget);
  });

  testWidgets('mes sin marcas: aviso y el saldo igual se ve', (tester) async {
    await tester.pumpWidget(_pagina(MisDiasServiceVacio()));
    await tester.pumpAndSettle();

    expect(
      find.text('No tienes marcas de asistencia en octubre 2026'),
      findsOneWidget,
    );
    expect(find.text('3 de 15 días disponibles'), findsOneWidget);
  });

  testWidgets('sin saldo asignado: avisa y muestra los días', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(MisDiasServiceSinSaldo(reloj: () => _hoy)));
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no tienes saldo de vacaciones asignado.'),
      findsOneWidget,
    );
    expect(find.byType(DiaTrabajadoCard), findsNWidgets(19));
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_pagina(MisDiasServiceError()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudieron cargar tus días trabajados'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('401: distingue sesión expirada de fallo de red', (tester) async {
    await tester.pumpWidget(_pagina(MisDiasServiceSinSesion()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
  });

  test('pide el mes por query, sin empleado_id, y no mezcla meses', () async {
    final peticiones = <PeticionFalsa>[];
    final servicio = MisDiasService(
      clienteFalso((p) {
        peticiones.add(p);
        if (p.ruta == '/saldos-vacacion/mio') return const <Object>[];
        // Un backend que ignora el filtro y manda otro mes de más.
        return [
          {'id': 'a', 'fecha': '2026-10-02', 'hora_entrada': '08:00:00'},
          {'id': 'b', 'fecha': '2026-09-30', 'hora_entrada': '08:00:00'},
          {'id': 'c', 'fecha': '2026-10-09', 'hora_entrada': '08:00:00'},
        ];
      }, demora: Duration.zero),
      sesionFalsa(),
    );

    final mes = await servicio.delMes(DateTime(2026, 10, 17));

    final asistencia = peticiones.firstWhere(
      (p) => p.ruta == '/asistencias/mias',
    );
    expect(asistencia.query, {'mes': '2026-10'});
    expect(peticiones.any((p) => p.query.containsKey('empleado_id')), isFalse);

    expect(mes.mes, DateTime(2026, 10));
    expect(mes.dias.map((d) => d.id), ['c', 'a']);
    expect(mes.saldo, isNull);
  });
}
