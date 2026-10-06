import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/features/reportes/report_config.dart';

void main() {
  test('serializa fuente, columnas, filtros y orden para vista previa', () {
    const config = ReportConfig(
      source: 'postulaciones',
      columns: ['postulante', 'fecha_postulacion'],
      filters: [
        ReportFilter(
          field: 'fecha_postulacion',
          operator: 'entre',
          value: ['2026-09-01T00:00:00', '2026-09-30T23:59:59.999999'],
        ),
      ],
      order: [ReportOrder(field: 'fecha_postulacion', direction: 'desc')],
    );

    expect(config.toJson(), {
      'fuente': 'postulaciones',
      'columnas': ['postulante', 'fecha_postulacion'],
      'filtros': [
        {
          'campo': 'fecha_postulacion',
          'operador': 'entre',
          'valor': ['2026-09-01T00:00:00', '2026-09-30T23:59:59.999999'],
        },
      ],
      'orden': [
        {'campo': 'fecha_postulacion', 'direccion': 'desc'},
      ],
    });
  });

  test('reconstruye una configuracion recibida del backend', () {
    final config = ReportConfig.fromJson({
      'fuente': 'vacantes',
      'columnas': ['titulo', 'estado'],
      'filtros': [
        {'campo': 'estado', 'operador': 'igual', 'valor': 'PUBLICADA'},
      ],
      'orden': [
        {'campo': 'titulo', 'direccion': 'asc'},
      ],
    });

    expect(config.source, 'vacantes');
    expect(config.filters.single.value, 'PUBLICADA');
    expect(config.order.single.direction, 'asc');
  });
}
