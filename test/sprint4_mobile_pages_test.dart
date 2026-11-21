import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';
import 'package:mobile_ssas_rrhh/features/capacitacion/my_skills_page.dart';
import 'package:mobile_ssas_rrhh/features/reportes/indicators_page.dart';

class Sprint4Api extends StaffApi {
  Sprint4Api() : super(baseUrl: 'http://localhost');

  @override
  Future<List<Map<String, dynamic>>> mySkills() async => [
    {
      'habilidad_nombre': 'Seguridad industrial',
      'nivel': 'CERTIFICADO',
      'curso_titulo': 'Prevención',
      'adquirida_en': '2026-11-20',
    },
  ];

  @override
  Future<Map<String, dynamic>> indicators(
    String from,
    String to, {
    String? companyId,
  }) async => {
    'rotacion': {
      'porcentaje': 10,
      'salidas': 1,
      'ingresos': 3,
      'dotacion_inicial': 10,
      'dotacion_final': 12,
    },
    'ausentismo': {'porcentaje': 2, 'dias_habiles_ausentes': 3},
    'tiempo_promedio_contratacion': {'dias': 14, 'contrataciones_medir': 2},
    'headcount_por_departamento': [
      {'departamento': 'Ventas', 'empleados': 4},
    ],
  };
}

void main() {
  testWidgets('CU37 muestra habilidades del endpoint', (tester) async {
    final api = Sprint4Api();
    await tester.pumpWidget(MaterialApp(home: MySkillsPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Seguridad industrial'), findsOneWidget);
    expect(find.textContaining('CERTIFICADO'), findsOneWidget);
    api.close();
  });

  testWidgets('T4-27 muestra variación de dotación y tarjetas', (tester) async {
    final api = Sprint4Api();
    await tester.pumpWidget(MaterialApp(home: IndicatorsPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Variación: 20.0%'), findsOneWidget);
    expect(find.text('Ausentismo'), findsOneWidget);
    expect(find.text('Ventas'), findsOneWidget);
    api.close();
  });
}
