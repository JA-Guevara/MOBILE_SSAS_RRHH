import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_pago.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Servicios FALSOS para desarrollar sin backend, igual que en las otras
/// features. Aquí sirven además para trabajar sin estar autenticado.
///
/// Para las 3 capturas de evidencia:
///   con boletas  -> BoletasServiceFalso
///   sin boletas  -> BoletasServiceVacio
///   con error    -> BoletasServiceError

/// Las dependencias reales no se usan en los fakes, pero el constructor de
/// BoletasService las pide. Se les pasa una instancia inerte.
AppHttpClient _clienteInerte() => AppHttpClient(baseUrl: 'falso');

/// Tres boletas, adrede DESORDENADAS, y una con líneas completas.
///
/// Los importes están cuadrados a mano: los haberes suman total_ganado, los
/// descuentos suman total_descuentos, y la resta da liquido_pagable. Si no
/// cuadraran, la captura mostraría una boleta que no se sostiene.
class BoletasServiceFalso extends BoletasService {
  BoletasServiceFalso() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<BoletaPago>> mias() async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 800));

    final lista =
        [_julio(), _agosto(), _junio()].map(BoletaPago.fromJson).toList()
          ..sort(BoletasService.masRecientePrimero);

    return lista;
  }

  @override
  Future<BoletaPago> detalle(String boletaId) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final crudo = switch (boletaId) {
      '31' => _agosto(),
      '30' => _julio(),
      _ => _junio(),
    };

    return BoletaPago.fromJson({...crudo, 'detalles': _lineas(boletaId)});
  }

  // ------------------------------------------------------------- las boletas

  static Map<String, dynamic> _agosto() => {
    'id': 31,
    'empresa_id': 1,
    'periodo_id': 8,
    'empleado_id': 7,
    'contrato_id': 12,
    'estructura_id': 2,
    'numero': 'BOL-2026-08-0031',
    'dias_trabajados': 30,
    'dias_no_trabajados': 0,
    'horas_extra': 4.5,
    'salario_basico': 6500,
    'total_ganado': 7362.50,
    'total_descuentos': 936.99,
    'liquido_pagable': 6425.51,
    'total_aportes_patronales': 1236.90,
    'estado': 'pagada',
    'fecha_generacion': '2026-08-28',
    'fecha_pago': '2026-08-30',
    'periodo': {
      'id': 8,
      'nombre': 'Agosto 2026',
      'mes': 8,
      'gestion': 2026,
      'fecha_inicio': '2026-08-01',
      'fecha_fin': '2026-08-31',
      'estado': 'cerrado',
    },
  };

  static Map<String, dynamic> _julio() => {
    'id': 30,
    'empresa_id': 1,
    'periodo_id': 7,
    'empleado_id': 7,
    'numero': 'BOL-2026-07-0030',
    'dias_trabajados': 28,
    'dias_no_trabajados': 2,
    'salario_basico': 6500,
    'total_ganado': 6933.33,
    'total_descuentos': 882.42,
    'liquido_pagable': 6050.91,
    'estado': 'pagada',
    'fecha_generacion': '2026-07-28',
    'fecha_pago': '2026-07-30',
    'periodo': {
      'id': 7,
      'nombre': 'Julio 2026',
      'mes': 7,
      'gestion': 2026,
      'estado': 'cerrado',
    },
  };

  static Map<String, dynamic> _junio() => {
    'id': 29,
    'empresa_id': 1,
    'periodo_id': 6,
    'empleado_id': 7,
    'numero': 'BOL-2026-06-0029',
    'dias_trabajados': 30,
    'dias_no_trabajados': 0,
    'salario_basico': 6500,
    'total_ganado': 6500,
    'total_descuentos': 827.45,
    'liquido_pagable': 5672.55,
    'estado': 'generada',
    'fecha_generacion': '2026-06-28',
    'periodo': {
      'id': 6,
      // Sin "nombre": se comprueba que la etiqueta se arma con mes y gestión.
      'mes': 6,
      'gestion': 2026,
      'estado': 'cerrado',
    },
  };

  // -------------------------------------------------------------- las líneas

  /// Líneas de la boleta de agosto. Las otras reutilizan la forma.
  ///
  /// La secuencia va adrede desordenada para comprobar que la pantalla la
  /// respeta, y hay una línea de tipo "aporte_patronal" que no es haber ni
  /// descuento: sirve para ver que no se pierde.
  static List<Map<String, dynamic>> _lineas(String boletaId) => [
    {
      'id': 5,
      'boleta_id': boletaId,
      'codigo': 'AFP',
      'nombre': 'Aporte AFP (laboral)',
      'tipo': 'descuento',
      'secuencia': 20,
      'base': 7362.50,
      'porcentaje': 12.71,
      'monto': 935.77,
    },
    {
      'id': 1,
      'boleta_id': boletaId,
      'codigo': 'BAS',
      'nombre': 'Salario básico',
      'tipo': 'haber',
      'secuencia': 1,
      'cantidad': 30,
      'monto': 6500,
    },
    {
      'id': 3,
      'boleta_id': boletaId,
      'codigo': 'HEX',
      'nombre': 'Horas extra',
      'tipo': 'haber',
      'secuencia': 3,
      'cantidad': 4.5,
      'base': 27.08,
      'monto': 121.86,
    },
    {
      'id': 2,
      'boleta_id': boletaId,
      'codigo': 'ANT',
      'nombre': 'Bono de antigüedad',
      'tipo': 'haber',
      'secuencia': 2,
      'base': 2500,
      'porcentaje': 11,
      'monto': 275,
    },
    {
      'id': 6,
      'boleta_id': boletaId,
      'codigo': 'ANT-S',
      'nombre': 'Anticipo de sueldo',
      'tipo': 'descuento',
      'secuencia': 21,
      'monto': 1.22,
    },
    {
      'id': 4,
      'boleta_id': boletaId,
      'codigo': 'DOM',
      'nombre': 'Domingos y feriados',
      'tipo': 'haber',
      'secuencia': 4,
      'cantidad': 2,
      'monto': 465.64,
    },
    {
      // >>> VERIFICA <<<  Este tipo no es haber ni descuento: cae en "otro"
      // y la pantalla lo muestra en su propio bloque en vez de perderlo.
      'id': 7,
      'boleta_id': boletaId,
      'codigo': 'CNS',
      'nombre': 'Aporte patronal CNS',
      'tipo': 'aporte_patronal',
      'secuencia': 30,
      'base': 7362.50,
      'porcentaje': 10,
      'monto': 736.25,
    },
  ];
}

/// El colaborador todavía no tiene ninguna boleta generada.
class BoletasServiceVacio extends BoletasService {
  BoletasServiceVacio() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<BoletaPago>> mias() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [];
  }
}

/// Lanza un error de red: para la captura del estado "con error".
class BoletasServiceError extends BoletasService {
  BoletasServiceError() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<BoletaPago>> mias() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException(
      'No se pudieron cargar tus boletas. '
      'Revisa tu conexión e inténtalo de nuevo.',
      statusCode: 503,
    );
  }

  @override
  Future<BoletaPago> detalle(String boletaId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException(
      'No se pudo cargar el detalle de la boleta. '
      'Revisa tu conexión e inténtalo de nuevo.',
      statusCode: 503,
    );
  }
}
