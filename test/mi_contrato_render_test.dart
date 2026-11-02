import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/equipo/model/contrato.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/model/historial_contratos.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/ui/mi_contrato_page.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _pagina(MiContratoService servicio) => MaterialApp(
  theme: AppTheme.light,
  home: MiContratoPage(service: servicio),
);

/// Lienzo alto: así se construye el historial completo.
void _lienzoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  test('textos: literales, salario y fechas', () {
    expect(HistorialContratos.legible('PLAZO_FIJO'), 'Plazo fijo');
    expect(HistorialContratos.legible('TIEMPO_COMPLETO'), 'Tiempo completo');
    expect(HistorialContratos.legible('HIBRIDO'), 'Híbrido');
    expect(HistorialContratos.legible('pasantia'), 'Pasantía');
    expect(HistorialContratos.legible(null), '—');

    expect(
      HistorialContratos.salario(
        Contrato.fromJson({'id': '1', 'salario_basico': '7000.00'}),
      ),
      'Bs 7.000,00',
    );
    expect(
      HistorialContratos.salario(
        Contrato.fromJson({'id': '1', 'salario_basico': 1500, 'moneda': 'USD'}),
      ),
      'USD 1.500,00',
    );
    expect(
      HistorialContratos.hasta(Contrato.fromJson({'id': '1'})),
      'Indefinido',
    );
  });

  testWidgets('el vigente con todos sus campos y el historial ordenado', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(MiContratoServiceFalso()));

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // El vigente: los campos de la tarea.
    expect(find.text('Mi contrato'), findsOneWidget);
    expect(find.text('Desarrollador Backend'), findsOneWidget);
    expect(find.text('N.º CTR-2026-007'), findsOneWidget);
    expect(find.text('Vigente'), findsOneWidget);
    expect(find.text('Bs 9.800,00'), findsOneWidget);
    expect(find.text('Híbrido'), findsOneWidget);
    expect(find.text('Tiempo completo'), findsOneWidget);
    expect(find.text('01/04/2026'), findsOneWidget);
    // "Indefinido" dos veces: el tipo de contrato y la fecha de fin.
    expect(find.text('Indefinido'), findsNWidgets(2));
    expect(find.text('Ascenso a Desarrollador Backend'), findsOneWidget);

    // El historial: llegó desordenado y se muestra del más nuevo al más viejo.
    expect(find.text('Versiones anteriores · 2'), findsOneWidget);
    expect(find.text('Finalizado'), findsNWidgets(2));
    expect(find.text('01/02/2025 al 31/03/2026'), findsOneWidget);
    expect(find.text('Bs 8.200,00 · Indefinido'), findsOneWidget);
    expect(find.text('Renovación a plazo indefinido'), findsOneWidget);
    expect(find.text('01/02/2024 al 31/01/2025'), findsOneWidget);
    expect(find.text('Bs 7.000,00 · Plazo fijo'), findsOneWidget);
    expect(find.text('Contrato inicial'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('01/02/2025 al 31/03/2026')).dy,
      lessThan(tester.getTopLeft(find.text('01/02/2024 al 31/01/2025')).dy),
    );

    // Solo lectura: no hay ningún botón que cambie algo.
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('primer contrato: sin versiones anteriores', (tester) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(MiContratoServicePrimerContrato()));
    await tester.pumpAndSettle();

    expect(find.text('Vigente'), findsOneWidget);
    expect(find.text('Desarrollador Junior'), findsOneWidget);
    expect(find.text('Plazo fijo'), findsOneWidget);
    expect(
      find.text(
        'Es tu primer contrato: todavía no tiene versiones anteriores.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin contrato vigente: avisa y muestra el historial', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(MiContratoServiceFinalizado()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No tienes un contrato vigente'),
      findsOneWidget,
    );
    expect(find.text('Vigente'), findsNothing);
    expect(find.text('Versiones anteriores · 3'), findsOneWidget);
  });

  testWidgets('sin contratos: estado vacío', (tester) async {
    await tester.pumpWidget(_pagina(MiContratoServiceVacio()));
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no tienes un contrato registrado'),
      findsOneWidget,
    );
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_pagina(MiContratoServiceError()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudo cargar tu contrato'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('401: distingue sesión expirada de fallo de red', (tester) async {
    await tester.pumpWidget(_pagina(MiContratoServiceSinSesion()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
  });

  test('pide sus contratos sin empleado_id y separa el vigente', () async {
    final peticiones = <PeticionFalsa>[];
    final servicio = MiContratoService(
      clienteFalso((p) {
        peticiones.add(p);
        if (p.ruta == '/cargos') return const <Object>[];
        return [
          {'id': 'a', 'fecha_inicio': '2023-01-01', 'estado': 'FINALIZADO'},
          {'id': 'c', 'fecha_inicio': '2026-01-01', 'estado': 'VIGENTE'},
          {'id': 'b', 'fecha_inicio': '2024-06-01', 'estado': 'FINALIZADO'},
        ];
      }, demora: Duration.zero),
      sesionFalsa(),
    );

    final historial = await servicio.historial();

    expect(peticiones.map((p) => p.ruta), ['/contratos/mios', '/cargos']);
    expect(peticiones.every((p) => p.query.isEmpty), isTrue);
    expect(historial.vigente?.id, 'c');
    expect(historial.anteriores.map((c) => c.id), ['b', 'a']);
  });
}
