import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend.
///
/// No reemplazan ningún método: le pasan a AsistenciaService un backend
/// falso que responde con filas de la tabla "asistencia" del diagrama del
/// Sprint 3. Corre el mismo código que contra rrhh-api.
///
/// Para las capturas de evidencia:
///   sin marcar    -> AsistenciaServiceSinMarcar
///   con entrada   -> AsistenciaServiceConEntrada
///   día completo  -> AsistenciaServiceDiaCompleto
///   con error     -> AsistenciaServiceError
///
/// Los tres primeros GUARDAN LO MARCADO en memoria, así que al pulsar el
/// botón la pantalla avanza de verdad: entrada -> salida -> deshabilitado.
/// No borres este archivo: también sirve para pruebas automatizadas.

/// La fila de "asistencia" con la entrada marcada. Solo columnas de la
/// tabla: id, empleado_id, fecha, hora_entrada, hora_salida,
/// latitud/longitud de entrada y salida, horas_trabajadas, horas_extra,
/// minutos_retraso, origen, estado, observacion.
Map<String, dynamic> _filaConEntrada({
  double latitud = -17.783327,
  double longitud = -63.182140,
}) => {
  'id': 'a1b2c3d4-0001',
  'empleado_id': 'e7',
  'fecha': '2026-08-29',
  'hora_entrada': '08:03:00',
  'hora_salida': null,
  'latitud_entrada': latitud,
  'longitud_entrada': longitud,
  'latitud_salida': null,
  'longitud_salida': null,
  'horas_trabajadas': null,
  'horas_extra': null,
  'minutos_retraso': 3,
  'origen': 'APP_MOVIL',
  'estado': 'PRESENTE',
  'observacion': null,
};

/// La misma fila con la salida: lo que calcularía el backend al cerrar.
Map<String, dynamic> _conSalida(
  Map<String, dynamic> fila, {
  double latitud = -17.783401,
  double longitud = -63.182233,
}) => {
  ...fila,
  'hora_salida': '17:12:00',
  'latitud_salida': latitud,
  'longitud_salida': longitud,
  'horas_trabajadas': 9.15,
  'horas_extra': 1.15,
};

/// Simula los tres endpoints con el día guardado en [fila]. Aplica las
/// mismas reglas que el backend: una entrada y una salida por día.
class _DiaFalso {
  Map<String, dynamic>? fila;

  _DiaFalso(this.fila);

  Object? responder(PeticionFalsa p) {
    if (p.es('GET', '/asistencias/hoy')) {
      if (fila == null) throw const ErrorFalso(404, 'Sin marca hoy.');
      return fila;
    }

    if (p.es('POST', '/asistencias/entrada')) {
      if (fila != null) {
        throw const ErrorFalso(409, 'Ya marcaste tu entrada hoy.');
      }
      final c = p.cuerpo ?? const {};
      return fila = _filaConEntrada(
        latitud: (c['latitud_entrada'] as num).toDouble(),
        longitud: (c['longitud_entrada'] as num).toDouble(),
      );
    }

    if (p.es('POST', '/asistencias/salida')) {
      final actual = fila;
      if (actual == null) {
        throw const ErrorFalso(409, 'Todavía no marcaste tu entrada de hoy.');
      }
      if (actual['hora_salida'] != null) {
        throw const ErrorFalso(409, 'Ya marcaste tu salida hoy.');
      }
      final c = p.cuerpo ?? const {};
      return fila = _conSalida(
        actual,
        latitud: (c['latitud_salida'] as num).toDouble(),
        longitud: (c['longitud_salida'] as num).toDouble(),
      );
    }

    throw ErrorFalso.rutaDesconocida(p);
  }
}

/// El colaborador todavía no marcó nada hoy: "—:— a —:—".
class AsistenciaServiceSinMarcar extends AsistenciaService {
  AsistenciaServiceSinMarcar()
    : super(clienteFalso(_DiaFalso(null).responder), sesionFalsa());
}

/// Ya marcó la entrada; falta la salida: "08:03 a —:—".
class AsistenciaServiceConEntrada extends AsistenciaService {
  AsistenciaServiceConEntrada()
    : super(
        clienteFalso(_DiaFalso(_filaConEntrada()).responder),
        sesionFalsa(),
      );
}

/// Día cerrado: el botón queda deshabilitado. "08:03 a 17:12".
class AsistenciaServiceDiaCompleto extends AsistenciaService {
  AsistenciaServiceDiaCompleto()
    : super(
        clienteFalso(_DiaFalso(_conSalida(_filaConEntrada())).responder),
        sesionFalsa(),
      );
}

/// No se puede ni consultar el día: para la captura del estado "con error".
class AsistenciaServiceError extends AsistenciaService {
  AsistenciaServiceError()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(
            503,
            'No se pudo cargar tu asistencia de hoy. '
            'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}
