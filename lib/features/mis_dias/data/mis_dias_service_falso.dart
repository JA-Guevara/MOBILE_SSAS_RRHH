import 'package:mobile_ssas_rrhh/features/mis_dias/data/mis_dias_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend (T3-21).
///
/// Igual que en el Sprint 3: no reemplazan ningún método, le pasan a
/// MisDiasService un backend falso que responde con filas de las tablas
/// "asistencia" y "saldo_vacacion" del diagrama.
///
/// Las marcas se ARMAN para el mes que se pida, hasta [hoy], así el mes
/// actual siempre se ve "vivo" en la demo. Son las de Julia Quispe: mismo
/// saldo de 3 de 15 días que en la bandeja del jefe (T3-22) y en T3-19.
///
/// Para las capturas de evidencia:
///   con días         -> MisDiasServiceFalso
///   mes sin marcas   -> MisDiasServiceVacio
///   sin saldo        -> MisDiasServiceSinSaldo
///   con error        -> MisDiasServiceError
///   sesión expirada  -> MisDiasServiceSinSesion
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Un mes normal: días completos, uno con horas extra, retrasos, un día sin
/// salida, un día de vacación sin marca y la jornada de hoy abierta.
class MisDiasServiceFalso extends MisDiasService {
  MisDiasServiceFalso({DateTime Function()? reloj})
    : super(
        clienteFalso(_BackendMisDias(reloj ?? DateTime.now).responder),
        sesionFalsa(),
      );
}

/// Todavía no tiene vacaciones asignadas: el saldo responde 404.
class MisDiasServiceSinSaldo extends MisDiasService {
  MisDiasServiceSinSaldo({DateTime Function()? reloj})
    : super(
        clienteFalso(
          _BackendMisDias(reloj ?? DateTime.now, conSaldo: false).responder,
        ),
        sesionFalsa(),
      );
}

/// Ninguna marca en el mes (por ejemplo, recién contratado).
class MisDiasServiceVacio extends MisDiasService {
  MisDiasServiceVacio()
    : super(
        clienteFalso(
          (p) => switch (p.ruta) {
            '/asistencias/mias' => const <Object>[],
            '/saldos-vacacion/mio' => _saldo,
            _ => throw ErrorFalso.rutaDesconocida(p),
          },
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red: para la captura del estado "con error".
class MisDiasServiceError extends MisDiasService {
  MisDiasServiceError()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(
            503,
            'No se pudieron cargar tus días trabajados. '
            'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// La sesión caducó: 401.
class MisDiasServiceSinSesion extends MisDiasService {
  MisDiasServiceSinSesion()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(401, 'No autenticado.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

class _BackendMisDias {
  final DateTime Function() reloj;
  final bool conSaldo;

  _BackendMisDias(this.reloj, {this.conSaldo = true});

  Object? responder(PeticionFalsa p) {
    if (p.es('GET', '/asistencias/mias')) return _marcasDelMes(p.query['mes']);
    if (p.es('GET', '/saldos-vacacion/mio')) {
      if (!conSaldo) throw const ErrorFalso(404, 'Sin saldo de vacaciones.');
      return _saldo;
    }
    throw ErrorFalso.rutaDesconocida(p);
  }

  /// Una fila por día hábil del mes, hasta hoy. Las reglas son fijas para
  /// que las pruebas sepan qué esperar:
  ///   - hoy: entrada a las 08:05, sin salida (en jornada), 5 min tarde
  ///   - día 15: vacación, no hay marca
  ///   - día 20: entrada a las 08:10 y sin salida (se olvidó de marcar)
  ///   - días múltiplo de 7: entrada a las 08:12, 12 min tarde
  ///   - días múltiplo de 5: salida a las 18:30, 9.5 h con 1.5 h extra
  ///   - el resto: 08:00 a 17:00, 8 h
  List<Map<String, Object?>> _marcasDelMes(String? mes) {
    final partes = (mes ?? '').split('-');
    final anio = int.tryParse(partes.first);
    final numMes = partes.length > 1 ? int.tryParse(partes[1]) : null;
    if (anio == null || numMes == null) {
      throw const ErrorFalso(422, 'El parámetro mes debe ser AAAA-MM.');
    }

    final ahora = reloj();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final filas = <Map<String, Object?>>[];

    for (var dia = 1; dia <= 31; dia++) {
      final fecha = DateTime(anio, numMes, dia);
      if (fecha.month != numMes || fecha.isAfter(hoy)) break;
      if (fecha.weekday > DateTime.friday || dia == 15) continue;

      final esHoy = fecha == hoy;
      final (entrada, retraso) = esHoy
          ? ('08:05:00', 5)
          : dia == 20
          ? ('08:10:00', 10)
          : dia % 7 == 0
          ? ('08:12:00', 12)
          : ('08:00:00', 0);
      final abierto = esHoy || dia == 20;
      final largo = dia % 5 == 0;

      filas.add({
        'id': 'as-$anio$numMes$dia',
        'empleado_id': 'e7',
        'fecha':
            '$anio-${numMes.toString().padLeft(2, '0')}-'
            '${dia.toString().padLeft(2, '0')}',
        'hora_entrada': entrada,
        'hora_salida': abierto ? null : (largo ? '18:30:00' : '17:00:00'),
        'latitud_entrada': -17.783327,
        'longitud_entrada': -63.182140,
        'latitud_salida': abierto ? null : -17.783401,
        'longitud_salida': abierto ? null : -63.182233,
        'horas_trabajadas': abierto ? null : (largo ? 9.5 : 8.0),
        'horas_extra': abierto ? null : (largo ? 1.5 : 0.0),
        'minutos_retraso': retraso,
        'origen': 'APP_MOVIL',
        'estado': retraso > 0 ? 'RETRASO' : 'PRESENTE',
        'observacion': null,
      });
    }
    return filas;
  }
}

/// Saldo de 2026 de Julia: el mismo que en T3-19 y en la bandeja del jefe.
const _saldo = {
  'id': 's5',
  'empleado_id': 'e7',
  'gestion': 2026,
  'dias_asignados': 15,
  'dias_usados': 12,
  'dias_saldo': 3,
  'fecha_corte': '2026-08-31',
  'fecha_actualizacion': '2026-08-31T18:00:00',
};
