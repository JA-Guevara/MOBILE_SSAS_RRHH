import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/legajo/model/documento_empleado.dart';
import 'package:mobile_ssas_rrhh/features/legajo/ui/legajo_page.dart';
import 'package:mobile_ssas_rrhh/features/legajo/ui/widgets/documento_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

/// Un día fijo, para que las pruebas de vigencia no dependan del reloj.
final _hoy = DateTime(2026, 10, 24);

DocumentoEmpleado _doc(String nombre, {DateTime? vence}) => DocumentoEmpleado(
  id: nombre,
  tipo: 'OTRO',
  nombre: nombre,
  fechaVencimiento: vence,
);

void main() {
  group('vigencia', () {
    test('los cuatro casos y sus bordes', () {
      DateTime en(int dias) => DateTime(2026, 10, 24 + dias);

      expect(_doc('a').vigencia(_hoy), Vigencia.sinVencimiento);
      expect(_doc('a', vence: en(-1)).vigencia(_hoy), Vigencia.vencido);
      // Vence hoy: todavía vale, pero hay que avisar.
      expect(_doc('a', vence: en(0)).vigencia(_hoy), Vigencia.porVencer);
      expect(
        _doc('a', vence: en(DocumentoEmpleado.diasAviso)).vigencia(_hoy),
        Vigencia.porVencer,
      );
      expect(
        _doc('a', vence: en(DocumentoEmpleado.diasAviso + 1)).vigencia(_hoy),
        Vigencia.vigente,
      );
    });

    test('la hora del vencimiento no cambia el día', () {
      final tarde = _doc('a', vence: DateTime(2026, 10, 25, 23, 59));
      expect(tarde.diasRestantes(DateTime(2026, 10, 24, 23, 0)), 1);
    });

    test('el aviso dice cuánto falta o cuánto pasó', () {
      DateTime en(int dias) => DateTime(2026, 10, 24 + dias);

      expect(_doc('a').avisoVencimiento(_hoy), '');
      expect(_doc('a', vence: en(0)).avisoVencimiento(_hoy), 'Vence hoy');
      expect(_doc('a', vence: en(1)).avisoVencimiento(_hoy), 'Vence mañana');
      expect(
        _doc('a', vence: en(12)).avisoVencimiento(_hoy),
        'Vence en 12 días',
      );
      expect(_doc('a', vence: en(-1)).avisoVencimiento(_hoy), 'Venció ayer');
      expect(
        _doc('a', vence: en(-5)).avisoVencimiento(_hoy),
        'Venció hace 5 días',
      );
    });

    test('ordena por urgencia: vencidos, por vencer, vigentes, sin fecha', () {
      DateTime en(int dias) => DateTime(2026, 10, 24 + dias);
      final lista = [
        _doc('Título'),
        _doc('CI', vence: en(900)),
        _doc('Examen', vence: en(20)),
        _doc('REJAP', vence: en(-5)),
        _doc('Primeros auxilios', vence: en(3)),
      ]..sort(DocumentoEmpleado.porUrgencia(_hoy));

      expect(lista.map((d) => d.nombre), [
        'REJAP',
        'Primeros auxilios',
        'Examen',
        'CI',
        'Título',
      ]);
    });
  });

  group('contrato del API', () {
    test('lee las columnas de documento_empleado y acepta tipos nuevos', () {
      final doc = DocumentoEmpleado.fromJson({
        'id': '3f2a9c1e-0b7d-4d2a-9a51-0c6f4f1b8e21',
        'empleado_id': 'a1b2c3d4-0000-4000-8000-000000000007',
        'tipo': 'LICENCIA_CONDUCIR',
        'nombre': 'Licencia de conducir',
        'archivo_url': 'https://archivos.test/licencia.pdf',
        'fecha_emision': '2024-03-05',
        'fecha_vencimiento': '2029-03-05',
      });

      expect(doc.id, '3f2a9c1e-0b7d-4d2a-9a51-0c6f4f1b8e21');
      expect(doc.archivoUrl, 'https://archivos.test/licencia.pdf');
      // Un tipo que la app no conoce se muestra tal cual, no se esconde.
      expect(doc.tipoEtiqueta, 'LICENCIA_CONDUCIR');
      expect(doc.emisionCorta, '05/03/2024');
      expect(doc.vencimientoCorto, '05/03/2029');
    });

    test('traduce los tipos de T3-02', () {
      DocumentoEmpleado t(String tipo) =>
          DocumentoEmpleado(id: '1', tipo: tipo, nombre: '');
      expect(t('CI').tipoEtiqueta, 'Carnet de identidad');
      expect(t('EXAMEN_MEDICO').tipoEtiqueta, 'Examen médico');
      expect(t('titulo').tipoEtiqueta, 'Título');
    });
  });

  testWidgets('con datos: avisa y pone lo urgente arriba', (tester) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final abiertos = <Uri>[];
    await tester.pumpWidget(
      _app(
        LegajoPage(
          service: LegajoServiceFalso(),
          abrirArchivo: (uri) async {
            abiertos.add(uri);
            return true;
          },
        ),
      ),
    );

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Mi legajo digital'), findsOneWidget);
    expect(find.text('1 documento vencido'), findsOneWidget);
    expect(
      find.text('2 documentos vencen en los próximos 30 días'),
      findsOneWidget,
    );

    // El fake llega desordenado: el vencido tiene que ir primero.
    final tarjetas = tester
        .widgetList<DocumentoCard>(find.byType(DocumentoCard))
        .map((c) => c.documento.nombre)
        .toList();
    expect(tarjetas.first, 'Certificado de antecedentes (REJAP)');
    expect(tarjetas.length, 6);
    expect(find.text('Venció hace 5 días'), findsOneWidget);
    expect(find.text('Vence en 12 días'), findsOneWidget);

    // Cinco documentos tienen archivo; el de primeros auxilios no.
    expect(find.text('Ver archivo'), findsNWidgets(5));
    await tester.tap(find.text('Ver archivo').first);
    await tester.pumpAndSettle();
    expect(abiertos.single.path, '/legajo/rejap.pdf');
  });

  testWidgets('si todo está vigente, el aviso lo dice en verde', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: AvisoVencimientos(documentos: [_doc('Título')], hoy: _hoy),
        ),
      ),
    );
    expect(find.text('Todos tus documentos están vigentes.'), findsOneWidget);
  });

  testWidgets('sin documentos: estado vacío', (tester) async {
    await tester.pumpWidget(_app(LegajoPage(service: LegajoServiceVacio())));
    await tester.pumpAndSettle();
    expect(
      find.text('Todavía no tienes documentos en tu legajo'),
      findsOneWidget,
    );
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(_app(LegajoPage(service: LegajoServiceError())));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No se pudieron cargar tus documentos'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('401: distingue sesión expirada de fallo de red', (tester) async {
    await tester.pumpWidget(
      _app(LegajoPage(service: LegajoServiceSinSesion())),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
  });
}
