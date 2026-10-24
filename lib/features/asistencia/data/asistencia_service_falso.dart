import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Servicios FALSOS para desarrollar sin backend, igual que en las otras
/// features. Aquí sirven además para trabajar sin estar autenticado.
///
/// Para las capturas de evidencia:
///   sin marcar    -> AsistenciaServiceSinMarcar
///   con entrada   -> AsistenciaServiceConEntrada
///   día completo  -> AsistenciaServiceDiaCompleto
///   con error     -> AsistenciaServiceError
///
/// Los tres primeros GUARDAN LO MARCADO en memoria, así que al pulsar el
/// botón la pantalla avanza de verdad: entrada -> salida -> deshabilitado.

/// Las dependencias reales no se usan en los fakes, pero el constructor de
/// AsistenciaService las pide. Se les pasa una instancia inerte.
AppHttpClient _clienteInerte() => AppHttpClient(baseUrl: 'falso');

/// Base de los fakes que sí dejan marcar: mantienen el día en memoria.
abstract class _AsistenciaFalsaBase extends AsistenciaService {
  _AsistenciaFalsaBase(this._actual)
    : super(_clienteInerte(), MemoryTokenStorage());

  Asistencia? _actual;

  @override
  Future<Asistencia?> deHoy() async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 700));
    return _actual;
  }

  @override
  Future<Asistencia> marcarEntrada({
    required double latitud,
    required double longitud,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (_actual?.tieneEntrada ?? false) {
      // Lo mismo que haría el backend con "una marca por día".
      throw const AppException('Ya marcaste tu entrada hoy.', statusCode: 409);
    }

    final marca = Asistencia(
      id: '1',
      empleadoId: '7',
      fecha: DateTime(2026, 8, 29),
      horaEntrada: '08:03:00',
      latitudEntrada: latitud,
      longitudEntrada: longitud,
      origen: Asistencia.origenMovil,
      estado: 'presente',
      minutosRetraso: 3,
    );
    _actual = marca;
    return marca;
  }

  @override
  Future<Asistencia> marcarSalida({
    required double latitud,
    required double longitud,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final previo = _actual;
    if (previo == null || !previo.tieneEntrada) {
      throw const AppException(
        'Todavía no marcaste tu entrada de hoy.',
        statusCode: 409,
      );
    }
    if (previo.tieneSalida) {
      throw const AppException('Ya marcaste tu salida hoy.', statusCode: 409);
    }

    final marca = Asistencia(
      id: previo.id,
      empleadoId: previo.empleadoId,
      fecha: previo.fecha,
      horaEntrada: previo.horaEntrada,
      horaSalida: '17:12:00',
      latitudEntrada: previo.latitudEntrada,
      longitudEntrada: previo.longitudEntrada,
      latitudSalida: latitud,
      longitudSalida: longitud,
      horasTrabajadas: 9.15,
      horasExtra: 1.15,
      minutosRetraso: previo.minutosRetraso,
      origen: previo.origen,
      estado: previo.estado,
    );
    _actual = marca;
    return marca;
  }
}

/// El colaborador todavía no marcó nada hoy: "—:— a —:—".
class AsistenciaServiceSinMarcar extends _AsistenciaFalsaBase {
  AsistenciaServiceSinMarcar() : super(null);
}

/// Ya marcó la entrada; falta la salida: "08:03 a —:—".
class AsistenciaServiceConEntrada extends _AsistenciaFalsaBase {
  AsistenciaServiceConEntrada()
    : super(
        Asistencia(
          id: '1',
          empleadoId: '7',
          fecha: DateTime(2026, 8, 29),
          horaEntrada: '08:03:00',
          latitudEntrada: -17.783327,
          longitudEntrada: -63.182140,
          origen: Asistencia.origenMovil,
          estado: 'presente',
          minutosRetraso: 3,
        ),
      );
}

/// Día cerrado: el botón queda deshabilitado. "08:03 a 17:12".
class AsistenciaServiceDiaCompleto extends _AsistenciaFalsaBase {
  AsistenciaServiceDiaCompleto()
    : super(
        Asistencia(
          id: '1',
          empleadoId: '7',
          fecha: DateTime(2026, 8, 29),
          horaEntrada: '08:03:00',
          horaSalida: '17:12:00',
          latitudEntrada: -17.783327,
          longitudEntrada: -63.182140,
          latitudSalida: -17.783401,
          longitudSalida: -63.182233,
          horasTrabajadas: 9.15,
          horasExtra: 1.15,
          minutosRetraso: 3,
          origen: Asistencia.origenMovil,
          estado: 'presente',
        ),
      );
}

/// No se puede ni consultar el día: para la captura del estado "con error".
class AsistenciaServiceError extends AsistenciaService {
  AsistenciaServiceError() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<Asistencia?> deHoy() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException(
      'No se pudo cargar tu asistencia de hoy. '
      'Revisa tu conexión e inténtalo de nuevo.',
      statusCode: 503,
    );
  }
}
