import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/model/entrevista.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/ui/consulta_entrevista_page.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/ui/entrevista_page.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

const _codigo = 'POST-8F4K2A1C';

void main() {
  testWidgets('por confirmar (virtual): datos y botón Confirmar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(EntrevistaPage(codigo: _codigo, service: EntrevistaServiceFalso())),
    );

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Código $_codigo'), findsOneWidget);
    expect(find.text('Desarrollador Backend'), findsOneWidget);
    expect(find.text('Por confirmar'), findsOneWidget);
    expect(find.text('Virtual'), findsOneWidget);
    expect(find.text('https://meet.google.com/abc-defg-hij'), findsOneWidget);
    expect(find.text('15:00 · 45 min'), findsOneWidget);
    expect(find.text('Confirmar asistencia'), findsOneWidget);
  });

  testWidgets('confirmar: pasa a confirmada y desaparece el botón', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(EntrevistaPage(codigo: _codigo, service: EntrevistaServiceFalso())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar asistencia'));
    await tester.pumpAndSettle();

    // Lienzo alto: el aviso queda debajo de la tarjeta y el ListView no
    // construye lo que no cabe en el tamaño por defecto (800×600).
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    expect(find.text('Confirmar asistencia'), findsNothing);
    expect(find.text('Asistencia confirmada'), findsOneWidget);
    expect(
      find.text('Confirmaste tu asistencia. Te esperamos.'),
      findsOneWidget,
    );
    // Sin aviso rojo: confirmar bien no debe mostrar ningún error.
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('presencial: muestra el lugar y no el enlace', (tester) async {
    await tester.pumpWidget(
      _app(
        EntrevistaPage(codigo: _codigo, service: EntrevistaServicePresencial()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Presencial'), findsOneWidget);
    expect(find.textContaining('Av. Cristo Redentor'), findsOneWidget);
    expect(find.text('Enlace'), findsNothing);
  });

  testWidgets('ya confirmada: sin botón', (tester) async {
    await tester.pumpWidget(
      _app(
        EntrevistaPage(codigo: _codigo, service: EntrevistaServiceConfirmada()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirmar asistencia'), findsNothing);
    expect(find.text('Asistencia confirmada'), findsOneWidget);
  });

  testWidgets('sin entrevista: estado vacío', (tester) async {
    await tester.pumpWidget(
      _app(EntrevistaPage(codigo: _codigo, service: EntrevistaServiceVacio())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no tienes una entrevista programada'),
      findsOneWidget,
    );
  });

  testWidgets('error al consultar: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(
      _app(EntrevistaPage(codigo: _codigo, service: EntrevistaServiceError())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo consultar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('error al confirmar: aviso y los datos siguen', (tester) async {
    await tester.pumpWidget(
      _app(
        EntrevistaPage(
          codigo: _codigo,
          service: EntrevistaServiceErrorAlConfirmar(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar asistencia'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo confirmar'), findsOneWidget);
    expect(find.text('Desarrollador Backend'), findsOneWidget);
    expect(find.text('Confirmar asistencia'), findsOneWidget);
  });

  testWidgets('consulta: rechaza el formato viejo TX-', (tester) async {
    await tester.pumpWidget(
      _app(
        ConsultaEntrevistaPage(
          service: EntrevistaServiceFalso(),
          codigoInicial: 'TX-8F4K2',
        ),
      ),
    );

    await tester.tap(find.text('Ver mi entrevista'));
    await tester.pump();

    expect(find.text('El código se ve así: POST-8F4K2A1C.'), findsOneWidget);
  });

  test('fromJson: claves del contrato propuesto y hora local', () {
    final e = Entrevista.fromJson({
      'data': {
        'id': 3,
        'codigo_seguimiento': _codigo,
        'vacante': 'Contador',
        'fecha_hora': '2030-01-15T14:00:00Z',
        'modalidad': 'PRESENCIAL',
        'lugar': '  ',
        'estado': 'CONFIRMADA',
      },
    });

    expect(e.id, 3);
    expect(e.vacanteTitulo, 'Contador');
    expect(e.modalidad, ModalidadEntrevista.presencial);
    expect(e.estado, EstadoEntrevista.confirmada);
    expect(e.lugar, isNull);
    expect(e.fechaHora.isUtc, isFalse);
    expect(e.puedeConfirmar, isFalse);
  });
}
