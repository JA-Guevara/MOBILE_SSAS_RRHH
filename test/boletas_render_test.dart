import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_detalle.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/periodo_nomina.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/boleta_detalle_page.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/boletas_page.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/widgets/seccion_detalle.dart';
import 'package:mobile_ssas_rrhh/shared/format/moneda.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

/// Lienzo alto: ListView.builder solo construye lo que cabe en pantalla.
void _lienzoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  test('la moneda se escribe como en Bolivia: millar con punto', () {
    expect(Moneda.bs(6425.51), 'Bs 6.425,51');
    expect(Moneda.bs(1234567.8), 'Bs 1.234.567,80');
    expect(Moneda.bs(0), 'Bs 0,00');
    expect(Moneda.bs(-1.22), '-Bs 1,22');
    // Redondeo a dos decimales, que es lo que exige una boleta.
    expect(Moneda.bs(6500.005), 'Bs 6.500,01');
    // Sin dato no es lo mismo que cero.
    expect(Moneda.bs(null), '—');

    expect(Moneda.porcentaje(12.71), '12,71%');
    expect(Moneda.porcentaje(11), '11%');
  });

  test('el tipo se interpreta y lo desconocido no se pierde', () {
    expect(BoletaDetalle.parseTipo('haber'), TipoDetalle.haber);
    expect(BoletaDetalle.parseTipo('HABERES'), TipoDetalle.haber);
    expect(BoletaDetalle.parseTipo('ingreso'), TipoDetalle.haber);
    expect(BoletaDetalle.parseTipo('descuento'), TipoDetalle.descuento);
    expect(BoletaDetalle.parseTipo('RETENCION'), TipoDetalle.descuento);
    // Lo que no encaje cae en "otro" y la pantalla lo muestra igual.
    expect(BoletaDetalle.parseTipo('aporte_patronal'), TipoDetalle.otro);
    expect(BoletaDetalle.parseTipo(null), TipoDetalle.otro);
  });

  test('el periodo sin nombre se arma con mes y gestión', () {
    const conNombre = PeriodoNomina(id: '8', nombre: 'Agosto 2026');
    expect(conNombre.etiqueta, 'Agosto 2026');

    const sinNombre = PeriodoNomina(id: '6', mes: 6, gestion: 2026);
    expect(sinNombre.etiqueta, 'Junio 2026');

    // Un mes fuera de rango no debe reventar la pantalla.
    const raro = PeriodoNomina(id: '1', mes: 13, gestion: 2026);
    expect(raro.etiqueta, 'Mes 13 2026');
  });

  testWidgets('lista: boletas ordenadas de la más reciente', (tester) async {
    await tester.pumpWidget(_app(BoletasPage(service: BoletasServiceFalso())));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Mis boletas'), findsOneWidget);

    // El fake las devuelve desordenadas: julio, agosto, junio.
    final titulos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((t) => t != null && t.contains('2026'))
        .toList();
    expect(titulos.first, 'Agosto 2026');

    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('Julio 2026'), findsOneWidget);
    // Junio no trae "nombre": la etiqueta se arma con mes y gestión.
    expect(find.text('Junio 2026'), findsOneWidget);

    expect(find.text('Bs 6.425,51'), findsOneWidget);
  });

  testWidgets('detalle: agrupa por tipo y ordena por secuencia', (
    tester,
  ) async {
    _lienzoAlto(tester);

    await tester.pumpWidget(
      _app(
        BoletaDetallePage(
          boletaId: '31',
          etiquetaPeriodo: 'Agosto 2026',
          service: BoletasServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HABERES'), findsOneWidget);
    expect(find.text('DESCUENTOS'), findsOneWidget);
    // La línea de tipo desconocido no se pierde: va en su propio bloque.
    expect(find.text('OTROS CONCEPTOS'), findsOneWidget);

    // El fake manda las líneas desordenadas; deben salir por secuencia.
    // Se mira dentro del bloque de haberes, no todos los Text de la
    // pantalla: "Salario básico" también es una etiqueta del resumen.
    final secciones = tester.widgetList<SeccionDetalle>(
      find.byType(SeccionDetalle),
    );

    final haberes = secciones.firstWhere((s) => s.titulo == 'Haberes');
    expect(haberes.lineas.map((l) => l.nombre).toList(), [
      'Salario básico', // secuencia 1
      'Bono de antigüedad', // secuencia 2
      'Horas extra', // secuencia 3
      'Domingos y feriados', // secuencia 4
    ]);

    final descuentos = secciones.firstWhere((s) => s.titulo == 'Descuentos');
    expect(descuentos.lineas.map((l) => l.nombre).toList(), [
      'Aporte AFP (laboral)', // secuencia 20
      'Anticipo de sueldo', // secuencia 21
    ]);

    // El cálculo explica de dónde sale el monto.
    expect(find.text('12,71% sobre Bs 7.362,50'), findsOneWidget);

    // Totales del backend y el líquido destacado.
    expect(find.text('Bs 7.362,50'), findsWidgets);
    expect(find.text('LÍQUIDO PAGABLE'), findsOneWidget);
    expect(find.text('Bs 6.425,51'), findsOneWidget);
  });

  testWidgets('sin boletas: estado vacío', (tester) async {
    await tester.pumpWidget(_app(BoletasPage(service: BoletasServiceVacio())));
    await tester.pumpAndSettle();

    expect(find.textContaining('Todavía no tienes boletas'), findsOneWidget);
  });

  testWidgets('error: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_app(BoletasPage(service: BoletasServiceError())));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudieron cargar tus boletas'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('error en el detalle: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(
      _app(
        BoletaDetallePage(
          boletaId: '31',
          etiquetaPeriodo: 'Agosto 2026',
          service: BoletasServiceError(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La cabecera se pinta desde el primer frame, sin esperar al detalle.
    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.textContaining('No se pudo cargar el detalle'), findsOneWidget);
  });
}
