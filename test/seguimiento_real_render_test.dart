import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/model/seguimiento_postulacion.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/ui/seguimiento_page.dart';

class _ServicioRealDePrueba extends SeguimientoService {
  _ServicioRealDePrueba() : super(baseUrl: 'falso');

  @override
  Future<SeguimientoPostulacion?> porCodigo(String codigo) async =>
      SeguimientoPostulacion.fromJson({
        'codigo_seguimiento': codigo,
        'estado': 'ACTIVA',
        'etapa': 'Postulación',
        'vacante': 'Auxiliar de farmacia',
        'fecha_postulacion': '2026-10-04T12:00:00',
        'fecha_ultimo_cambio': '2026-10-04T12:00:00',
      });
}

void main() {
  testWidgets('CU-11 muestra solo los datos que entrega la API pública', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SeguimientoPage(
      codigo: 'POST-A1B2C3D4', service: _ServicioRealDePrueba(),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Auxiliar de farmacia'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
    expect(find.text('Postulación'), findsNWidgets(2));
    expect(find.text('04/10/2026'), findsNWidgets(2));
    expect(find.text('Oferta'), findsNothing);
  });
}
