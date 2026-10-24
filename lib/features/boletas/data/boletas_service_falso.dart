import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend.
///
/// No reemplazan ningún método: le pasan a BoletasService un backend falso
/// que responde con filas de las tablas del diagrama del Sprint 3
/// (boleta_pago, periodo_nomina y boleta_detalle), cada una por su lado.
/// La unión por periodo_id y boleta_id la hace el servicio real.
///
/// Para las capturas de evidencia:
///   con boletas -> BoletasServiceFalso
///   vacío       -> BoletasServiceVacio
///   con error   -> BoletasServiceError
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Tres boletas, adrede DESORDENADAS, y una con líneas completas.
///
/// Los importes están cuadrados a mano: los haberes suman total_ganado, los
/// descuentos suman total_descuentos, y la resta da liquido_pagable. Si no
/// cuadraran, la captura mostraría una boleta que no se sostiene.
class BoletasServiceFalso extends BoletasService {
  BoletasServiceFalso() : super(clienteFalso(_responder), sesionFalsa());

  static Object? _responder(PeticionFalsa p) {
    if (p.es('GET', '/boletas')) return [_julio, _agosto, _junio];
    if (p.es('GET', '/periodos-nomina')) return _periodos;

    for (final boleta in [_agosto, _julio, _junio]) {
      final id = boleta['id'];
      if (p.es('GET', '/boletas/$id')) return boleta;
      if (p.es('GET', '/boletas/$id/detalles')) return _lineas(id as String);
    }

    if (p.metodo == 'GET' && p.ruta.startsWith('/boletas/')) {
      throw const ErrorFalso(404, 'La boleta no existe.');
    }
    throw ErrorFalso.rutaDesconocida(p);
  }

  // ------------------------------------------------- boleta_pago (3 filas)

  static const _agosto = {
    'id': 'b31',
    'empresa_id': 'emp1',
    'periodo_id': 'p8',
    'empleado_id': 'e7',
    'contrato_id': 'c12',
    'estructura_id': 'es2',
    'numero': 'BOL-2026-08-0031',
    'dias_trabajados': 30,
    'dias_no_trabajados': 0,
    'horas_extra': 4.5,
    'salario_basico': 6500,
    'total_ganado': 7362.50,
    'total_descuentos': 936.99,
    'liquido_pagable': 6425.51,
    'total_aportes_patronales': 1236.90,
    'estado': 'PAGADA',
    'fecha_generacion': '2026-08-28',
    'fecha_pago': '2026-08-30',
  };

  static const _julio = {
    'id': 'b30',
    'empresa_id': 'emp1',
    'periodo_id': 'p7',
    'empleado_id': 'e7',
    'contrato_id': 'c12',
    'estructura_id': 'es2',
    'numero': 'BOL-2026-07-0030',
    'dias_trabajados': 28,
    'dias_no_trabajados': 2,
    'horas_extra': 0,
    'salario_basico': 6500,
    'total_ganado': 6933.33,
    'total_descuentos': 882.42,
    'liquido_pagable': 6050.91,
    'total_aportes_patronales': 1158.56,
    'estado': 'PAGADA',
    'fecha_generacion': '2026-07-28',
    'fecha_pago': '2026-07-30',
  };

  static const _junio = {
    'id': 'b29',
    'empresa_id': 'emp1',
    'periodo_id': 'p6',
    'empleado_id': 'e7',
    'contrato_id': 'c12',
    'estructura_id': 'es2',
    'numero': 'BOL-2026-06-0029',
    'dias_trabajados': 30,
    'dias_no_trabajados': 0,
    'horas_extra': 0,
    'salario_basico': 6500,
    'total_ganado': 6500,
    'total_descuentos': 827.45,
    'liquido_pagable': 5672.55,
    'total_aportes_patronales': 1086.15,
    'estado': 'GENERADA',
    'fecha_generacion': '2026-06-28',
    'fecha_pago': null,
  };

  // ---------------------------------------------- periodo_nomina (3 filas)

  static const _periodos = [
    {
      'id': 'p8',
      'empresa_id': 'emp1',
      'nombre': 'Agosto 2026',
      'mes': 8,
      'gestion': 2026,
      'fecha_inicio': '2026-08-01',
      'fecha_fin': '2026-08-31',
      'estado': 'PAGADO',
      'fecha_cierre': '2026-08-30',
    },
    {
      'id': 'p7',
      'empresa_id': 'emp1',
      'nombre': 'Julio 2026',
      'mes': 7,
      'gestion': 2026,
      'fecha_inicio': '2026-07-01',
      'fecha_fin': '2026-07-31',
      'estado': 'CERRADO',
      'fecha_cierre': '2026-07-30',
    },
    {
      'id': 'p6',
      'empresa_id': 'emp1',
      // Sin "nombre": se comprueba que la etiqueta se arma con mes y gestión.
      'nombre': null,
      'mes': 6,
      'gestion': 2026,
      'fecha_inicio': '2026-06-01',
      'fecha_fin': '2026-06-30',
      'estado': 'CERRADO',
      'fecha_cierre': '2026-06-30',
    },
  ];

  // ---------------------------------------------- boleta_detalle (7 filas)

  /// Líneas de la boleta. La secuencia va adrede desordenada para comprobar
  /// que la pantalla la respeta, y hay una línea APORTE_PATRONAL que no es
  /// haber ni descuento: sirve para ver que no se pierde.
  static List<Map<String, dynamic>> _lineas(String boletaId) => [
    _linea(
      boletaId,
      'd5',
      'r5',
      'AFP',
      'Aporte AFP (laboral)',
      'DESCUENTO',
      20,
      base: 7362.50,
      porcentaje: 12.71,
      monto: 935.77,
    ),
    _linea(
      boletaId,
      'd1',
      'r1',
      'BAS',
      'Salario básico',
      'HABER',
      1,
      cantidad: 30,
      monto: 6500,
    ),
    _linea(
      boletaId,
      'd3',
      'r3',
      'HEX',
      'Horas extra',
      'HABER',
      3,
      cantidad: 4.5,
      base: 27.08,
      monto: 121.86,
    ),
    _linea(
      boletaId,
      'd2',
      'r2',
      'ANT',
      'Bono de antigüedad',
      'HABER',
      2,
      base: 2500,
      porcentaje: 11,
      monto: 275,
    ),
    _linea(
      boletaId,
      'd6',
      'r6',
      'ANT-S',
      'Anticipo de sueldo',
      'DESCUENTO',
      21,
      monto: 1.22,
    ),
    _linea(
      boletaId,
      'd4',
      'r4',
      'DOM',
      'Domingos y feriados',
      'HABER',
      4,
      cantidad: 2,
      monto: 465.64,
    ),
    _linea(
      boletaId,
      'd7',
      'r7',
      'CNS',
      'Aporte patronal CNS',
      'APORTE_PATRONAL',
      30,
      base: 7362.50,
      porcentaje: 10,
      monto: 736.25,
    ),
  ];

  /// Una fila de boleta_detalle con TODAS sus columnas: id, boleta_id,
  /// regla_id, codigo, nombre, tipo, secuencia, cantidad, base,
  /// porcentaje, monto.
  static Map<String, dynamic> _linea(
    String boletaId,
    String id,
    String reglaId,
    String codigo,
    String nombre,
    String tipo,
    int secuencia, {
    num? cantidad,
    num? base,
    num? porcentaje,
    required num monto,
  }) => {
    'id': '$boletaId-$id',
    'boleta_id': boletaId,
    'regla_id': reglaId,
    'codigo': codigo,
    'nombre': nombre,
    'tipo': tipo,
    'secuencia': secuencia,
    'cantidad': cantidad,
    'base': base,
    'porcentaje': porcentaje,
    'monto': monto,
  };
}

/// El colaborador todavía no tiene ninguna boleta generada.
class BoletasServiceVacio extends BoletasService {
  BoletasServiceVacio()
    : super(
        clienteFalso(
          (p) => p.es('GET', '/periodos-nomina') || p.es('GET', '/boletas')
              ? const <Object>[]
              : throw ErrorFalso.rutaDesconocida(p),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red: para la captura del estado "con error".
class BoletasServiceError extends BoletasService {
  BoletasServiceError()
    : super(
        clienteFalso(
          (p) => throw ErrorFalso(
            503,
            p.ruta.startsWith('/boletas/')
                ? 'No se pudo cargar el detalle de la boleta. '
                      'Revisa tu conexión e inténtalo de nuevo.'
                : 'No se pudieron cargar tus boletas. '
                      'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}
