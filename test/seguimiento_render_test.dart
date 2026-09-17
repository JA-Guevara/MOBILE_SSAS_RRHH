import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/ui/seguimiento_page.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

void main() {
  testWidgets('con datos: dibuja los 5 hitos de la maqueta', (tester) async {
    await tester.pumpWidget(
      _app(
        SeguimientoPage(codigo: 'TX-8F4K2', service: SeguimientoServiceFalso()),
      ),
    );

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Estado 2: con datos
    expect(find.text('Código TX-8F4K2'), findsOneWidget);
    expect(find.text('Mi postulación'), findsOneWidget);
    expect(find.text('Desarrollador Backend'), findsOneWidget);
    expect(find.text('Textiles del Oriente'), findsOneWidget);

    expect(find.text('Postulación recibida'), findsOneWidget);
    expect(find.text('20/08 · 14:02'), findsOneWidget);
    expect(find.text('22/08 · afinidad IA 81%'), findsOneWidget);
    expect(find.text('26/08 · 10:00 · virtual'), findsOneWidget);
    expect(find.text('Oferta'), findsOneWidget);
    expect(find.text('Contratado'), findsOneWidget);
  });

  testWidgets('código no encontrado: estado vacío', (tester) async {
    await tester.pumpWidget(
      _app(
        SeguimientoPage(codigo: 'TX-00000', service: SeguimientoServiceVacio()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No encontramos ninguna postulación'),
      findsOneWidget,
    );
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(
      _app(
        SeguimientoPage(codigo: 'TX-8F4K2', service: SeguimientoServiceError()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo consultar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
