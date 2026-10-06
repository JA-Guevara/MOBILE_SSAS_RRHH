import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';
import 'package:mobile_ssas_rrhh/features/reportes/report_config.dart';
import 'package:mobile_ssas_rrhh/features/reportes/reportes_page.dart';

class _ReportApi extends StaffApi {
  _ReportApi() : super(baseUrl: 'https://example.test/api/v1');

  ReportConfig? received;

  @override
  Future<List<Map<String, dynamic>>> reportCatalog() async => [
    {
      'codigo': 'vacantes',
      'nombre': 'Vacantes',
      'columnas': ['titulo', 'estado'],
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> savedReports({String? empresaId}) async =>
      [];

  @override
  Future<Map<String, dynamic>> previewReport(
    ReportConfig config, {
    String? empresaId,
    int page = 1,
    int perPage = 25,
  }) async {
    received = config;
    return {
      'columnas': config.columns,
      'items': [
        {'titulo': 'Analista', 'estado': 'PUBLICADA'},
      ],
      'total': 1,
      'page': page,
      'per_page': perPage,
    };
  }
}

void main() {
  testWidgets('muestra catalogo y consulta vista previa con la fuente real', (
    tester,
  ) async {
    final api = _ReportApi();
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportesPage(
          api: api,
          permissions: const {'reportes:ver', 'reportes:ejecutar'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fuente y columnas'), findsOneWidget);
    final pageScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Vista previa'),
      200,
      scrollable: pageScroll,
    );
    await tester.tap(find.text('Vista previa'));
    await tester.pumpAndSettle();

    expect(api.received?.source, 'vacantes');
    expect(api.received?.columns, ['titulo', 'estado']);
    await tester.scrollUntilVisible(
      find.text('Analista'),
      200,
      scrollable: pageScroll,
    );
    expect(find.text('1 registros'), findsOneWidget);
    expect(find.text('Analista'), findsOneWidget);
  });
}
