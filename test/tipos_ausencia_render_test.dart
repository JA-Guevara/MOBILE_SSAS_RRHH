import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/model/reglas_tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/ui/tipos_ausencia_page.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _pagina(TiposAusenciaService servicio) => MaterialApp(
  theme: AppTheme.light,
  home: TiposAusenciaPage(service: servicio),
);

/// Lienzo alto: así se construyen la lista y el formulario completos.
void _lienzoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder get _guardar => find.widgetWithText(ElevatedButton, 'Guardar cambios');

bool _guardarHabilitado(WidgetTester tester) =>
    tester.widget<ElevatedButton>(_guardar).onPressed != null;

/// Abre la lista con el backend falso y toca el tipo [nombre].
Future<void> _abrir(
  WidgetTester tester,
  String nombre, {
  TiposAusenciaService? servicio,
}) async {
  _lienzoAlto(tester);
  await tester.pumpWidget(_pagina(servicio ?? TiposAusenciaServiceFalso()));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nombre));
  await tester.pumpAndSettle();
}

void main() {
  test('reglas: nombre, código único, tope y textos', () {
    expect(ReglasTipoAusencia.nombre('  '), isNotNull);
    expect(ReglasTipoAusencia.nombre('Vacación'), isNull);
    expect(ReglasTipoAusencia.nombre('x' * 121), isNotNull);

    expect(ReglasTipoAusencia.codigo('', const []), isNotNull);
    expect(ReglasTipoAusencia.codigo('A B', const []), isNotNull);
    expect(
      ReglasTipoAusencia.codigo('med', const ['MED']),
      'Ya hay otro tipo de ausencia con el código MED.',
    );
    expect(ReglasTipoAusencia.codigo('VAC', const ['MED']), isNull);

    expect(ReglasTipoAusencia.tope(''), isNull); // sin tope
    expect(ReglasTipoAusencia.tope('15'), isNull);
    expect(ReglasTipoAusencia.tope('0'), isNotNull);
    expect(ReglasTipoAusencia.tope('366'), isNotNull);

    expect(ReglasTipoAusencia.textoTope(null), 'Sin tope anual');
    expect(ReglasTipoAusencia.textoTope(1), 'Hasta 1 día al año');
    expect(ReglasTipoAusencia.textoTope(15), 'Hasta 15 días al año');

    // El cuerpo que se guarda: las ocho columnas, sin id ni empresa_id.
    const tipo = TipoAusencia(id: 't1', empresaId: 'emp1', nombre: 'Vacación');
    expect(tipo.toJson().keys.toSet(), {
      'nombre',
      'codigo',
      'es_remunerado',
      'descuenta_vacacion',
      'dias_maximos_anio',
      'requiere_aprobacion',
      'requiere_documento',
      'activo',
    });
  });

  testWidgets('lista: cada tipo con sus condiciones, los inactivos al final', (
    tester,
  ) async {
    _lienzoAlto(tester);
    await tester.pumpWidget(_pagina(TiposAusenciaServiceFalso()));

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Tipos de ausencia'), findsOneWidget);
    expect(find.text('4 tipos · 3 activos'), findsOneWidget);

    // Los ocho campos de la tarea se ven en la tarjeta.
    expect(find.text('VAC'), findsOneWidget);
    expect(find.text('Hasta 15 días al año'), findsOneWidget);
    expect(find.text('Hasta 10 días al año'), findsOneWidget);
    expect(find.text('Sin tope anual'), findsNWidgets(2));
    expect(find.text('Con goce de haber'), findsNWidgets(2));
    expect(find.text('Sin goce de haber'), findsNWidgets(2));
    expect(find.text('Descuenta vacación'), findsOneWidget);
    expect(find.text('Requiere documento'), findsNWidgets(3));
    expect(find.text('Inactivo'), findsOneWidget);

    // Activos por nombre y, después, el inactivo (llegaron desordenados).
    double dy(String texto) => tester.getTopLeft(find.text(texto)).dy;
    expect(dy('Baja médica'), lessThan(dy('Permiso personal')));
    expect(dy('Permiso personal'), lessThan(dy('Vacación')));
    expect(dy('Vacación'), lessThan(dy('Licencia por estudios')));
  });

  testWidgets('editar el tope: se guarda y la lista lo muestra', (
    tester,
  ) async {
    await _abrir(tester, 'Vacación');

    // El formulario llega con los datos actuales y "Guardar" apagado.
    expect(find.text('Tope anual (días)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'VAC'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '15'), findsOneWidget);
    expect(_guardarHabilitado(tester), isFalse);

    // El tope es el tercer campo: se busca por posición porque su texto
    // cambia en la prueba.
    final tope = find.byType(TextFormField).at(2);
    await tester.enterText(tope, '20');
    await tester.pump();
    expect(_guardarHabilitado(tester), isTrue);

    // Volver al valor original no es un cambio.
    await tester.enterText(tope, '15');
    await tester.pump();
    expect(_guardarHabilitado(tester), isFalse);

    await tester.enterText(tope, '20');
    await tester.pump();
    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    // De vuelta en la lista, recargada desde el backend.
    expect(find.text('4 tipos · 3 activos'), findsOneWidget);
    expect(find.text('Hasta 20 días al año'), findsOneWidget);
    expect(find.text('Hasta 15 días al año'), findsNothing);
    expect(
      find.text('Se guardaron los cambios de "Vacación".'),
      findsOneWidget,
    );
  });

  testWidgets('validaciones: nombre vacío, código repetido y tope', (
    tester,
  ) async {
    await _abrir(tester, 'Permiso personal');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Permiso personal'),
      '',
    );
    // El código se escribe en mayúsculas solo.
    await tester.enterText(find.widgetWithText(TextFormField, 'PER'), 'med');
    // El tope está vacío (sin tope): es el tercer campo del formulario.
    await tester.enterText(find.byType(TextFormField).at(2), '400');
    await tester.pump();
    expect(find.widgetWithText(TextFormField, 'MED'), findsOneWidget);

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(
      find.text('Escribe el nombre del tipo de ausencia.'),
      findsOneWidget,
    );
    expect(
      find.text('Ya hay otro tipo de ausencia con el código MED.'),
      findsOneWidget,
    );
    expect(find.textContaining('El tope va de 1 a 365 días'), findsOneWidget);
    // No se fue a la lista.
    expect(_guardar, findsOneWidget);
  });

  testWidgets('reactivar un tipo inactivo', (tester) async {
    await _abrir(tester, 'Licencia por estudios');

    expect(
      find.text('Los colaboradores ya no lo ven al pedir una ausencia.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Activo'));
    await tester.pump();
    expect(find.text('Los colaboradores pueden elegirlo.'), findsOneWidget);

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(find.text('4 tipos · 4 activos'), findsOneWidget);
    expect(find.text('Inactivo'), findsNothing);
  });

  testWidgets('falla al guardar: aviso y no se pierde lo escrito', (
    tester,
  ) async {
    await _abrir(
      tester,
      'Vacación',
      servicio: TiposAusenciaServiceErrorAlGuardar(),
    );

    await tester.enterText(find.widgetWithText(TextFormField, '15'), '20');
    await tester.pump();
    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudieron guardar los cambios'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, '20'), findsOneWidget);
    expect(_guardar, findsOneWidget);
  });

  testWidgets('sin tipos: estado vacío', (tester) async {
    await tester.pumpWidget(_pagina(TiposAusenciaServiceVacio()));
    await tester.pumpAndSettle();

    expect(
      find.text('Tu empresa todavía no tiene tipos de ausencia'),
      findsOneWidget,
    );
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_pagina(TiposAusenciaServiceError()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudieron cargar los tipos de ausencia'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('401: sesión expirada', (tester) async {
    await tester.pumpWidget(_pagina(TiposAusenciaServiceSinSesion()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
  });

  testWidgets('403: no es administrador, distinto de sesión expirada', (
    tester,
  ) async {
    await tester.pumpWidget(_pagina(TiposAusenciaServiceSinPermiso()));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Esta configuración es solo para el administrador de la empresa.',
      ),
      findsOneWidget,
    );
  });

  test('las rutas: GET con inactivos y PUT con las ocho columnas', () async {
    final peticiones = <PeticionFalsa>[];
    final servicio = TiposAusenciaService(
      clienteFalso((p) {
        peticiones.add(p);
        if (p.metodo == 'PUT') return {'id': 't1', ...?p.cuerpo};
        return [
          {'id': 't1', 'nombre': 'Vacación', 'codigo': 'VAC', 'activo': true},
        ];
      }, demora: Duration.zero),
      sesionFalsa(),
    );

    final tipos = await servicio.listar();
    final guardado = await servicio.guardar(
      const TipoAusencia(
        id: 't1',
        empresaId: 'emp1',
        nombre: 'Vacación anual',
        codigo: 'VAC',
        diasMaximosAnio: 20,
      ),
    );

    expect(tipos.single.codigo, 'VAC');
    expect(peticiones.map((p) => '$p'), [
      'GET /personal/tipos-ausencia',
      'PUT /personal/tipos-ausencia/t1',
    ]);
    expect(peticiones.first.query, {'incluir_inactivos': 'true'});
    expect(peticiones.last.cuerpo!.containsKey('empresa_id'), isFalse);
    expect(peticiones.last.cuerpo!['dias_maximos_anio'], 20);
    expect(guardado.nombre, 'Vacación anual');
  });
}
