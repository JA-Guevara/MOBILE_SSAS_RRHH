import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/ui/vacantes_publicas_page.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/ui/widgets/vacante_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Portal público de empleos (T1-18 · HU-01 · CU-01).
///
/// Comprueba los CUATRO estados de la pantalla contra los servicios falsos,
/// que son los mismos que se usan para las capturas de evidencia.

Widget _app(VacantesService service) => MaterialApp(
  theme: AppTheme.light,
  home: VacantesPublicasPage(
    slug: 'textiles-oriente',
    empresaNombre: 'Textiles del Oriente',
    service: service,
  ),
);

void main() {
  test('el modelo arma el subtítulo y la fecha corta', () {
    final vacante = Vacante.fromJson({
      'id': 1,
      'titulo': 'Desarrollador Backend',
      'modalidad': 'Híbrido',
      'ubicacion': 'Santa Cruz',
      'fecha_cierre': '2026-09-10',
    });
    expect(vacante.subtitulo, 'Híbrido · Santa Cruz');
    expect(vacante.fechaCierreCorta, '10/09');

    // Lo que el backend no mande no debe dejar separadores sueltos.
    final soloModalidad = Vacante.fromJson({
      'id': 2,
      'titulo': 'Auxiliar Contable',
      'modalidad': 'Presencial',
    });
    expect(soloModalidad.subtitulo, 'Presencial');
    expect(soloModalidad.fechaCierreCorta, '');

    // Y una vacante sin nada más que el título tampoco revienta.
    final pelada = Vacante.fromJson({'id': 3, 'titulo': 'Pasante'});
    expect(pelada.subtitulo, '');
  });

  testWidgets('con datos: una tarjeta por vacante', (tester) async {
    await tester.pumpWidget(_app(VacantesServiceFalso()));

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // Estado 2: con datos
    expect(find.text('Portal de empleos'), findsOneWidget);
    expect(find.text('SSAH · Textiles del Oriente'), findsOneWidget);

    expect(find.byType(VacanteCard), findsNWidgets(2));
    expect(find.text('Desarrollador Backend'), findsOneWidget);
    expect(find.text('Auxiliar Contable'), findsOneWidget);
    expect(find.text('Híbrido · Santa Cruz'), findsOneWidget);
  });

  testWidgets('sin vacantes: estado vacío', (tester) async {
    await tester.pumpWidget(_app(VacantesServiceVacio()));
    await tester.pumpAndSettle();

    expect(find.textContaining('No hay vacantes publicadas'), findsOneWidget);
    expect(find.byType(VacanteCard), findsNothing);
  });

  testWidgets('error: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_app(VacantesServiceError()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudieron cargar las vacantes'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(VacanteCard), findsNothing);
  });

  testWidgets('sin servicio de postulación, tocar una tarjeta no navega', (
    tester,
  ) async {
    // La pantalla se puede capturar sola: postulacionesService es opcional.
    await tester.pumpWidget(_app(VacantesServiceFalso()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Desarrollador Backend'));
    await tester.pumpAndSettle();

    // Seguimos en el portal: no se abrió ningún formulario.
    expect(find.text('Portal de empleos'), findsOneWidget);
  });
}
