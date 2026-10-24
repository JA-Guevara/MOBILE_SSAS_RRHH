import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/miembro_equipo.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Servicios FALSOS para desarrollar sin backend, igual que en las otras
/// features. En T3-29 son OBLIGATORIOS por ahora: el backend no tiene
/// contrato (T3-01) ni asistencia (T3-05).
///
/// Para las capturas de evidencia:
///   con equipo     -> EquipoServiceFalso
///   vacío          -> EquipoServiceVacio
///   con error      -> EquipoServiceError
///   no es jefe     -> EquipoServiceSinPermiso
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Las dependencias reales no se usan en los fakes, pero el constructor de
/// EquipoService las pide. Se les pasa una instancia inerte.
AppHttpClient _clienteInerte() => AppHttpClient(baseUrl: 'falso');

/// Seis personas que cubren los cuatro estados del día, adrede
/// DESORDENADAS para comprobar que la lista sale por nombre.
class EquipoServiceFalso extends EquipoService {
  EquipoServiceFalso() : super(_clienteInerte(), MemoryTokenStorage());

  /// Mismas claves que lee MiembroEquipo.fromJson. Se mezclan las dos
  /// formas que acepta (empleado plano y anidado) a propósito.
  static final datos = <Map<String, dynamic>>[
    {
      'empleado': {
        'id': 'e12',
        'codigo': 'EMP-012',
        'nombres': 'Marco',
        'apellido_paterno': 'Terceros',
        'apellido_materno': 'Vaca',
      },
      'cargo': {'id': 'c3', 'nombre': 'Analista contable'},
      'asistencia': {
        'fecha': '2026-10-24',
        'hora_entrada': '08:12:00',
        'hora_salida': null,
        'minutos_retraso': 12,
        'estado': 'TARDANZA',
      },
    },
    {
      'empleado': {
        'id': 'e10',
        'codigo': 'EMP-010',
        'nombres': 'Lucía',
        'apellido_paterno': 'Fernández',
        'apellido_materno': 'Rojas',
      },
      'cargo': {'id': 'c2', 'nombre': 'Asistente de RR. HH.'},
      'asistencia': {
        'fecha': '2026-10-24',
        'hora_entrada': '07:56:00',
        'hora_salida': null,
        'minutos_retraso': 0,
        'estado': 'PRESENTE',
      },
    },
    {
      'empleado_id': 'e15',
      'codigo': 'EMP-015',
      'nombres': 'Rosa',
      'apellido_paterno': 'Mamani',
      'cargo': 'Auxiliar contable',
      // Todavía no marcó: la fila llega sin asistencia.
      'asistencia': null,
    },
    {
      'empleado': {
        'id': 'e11',
        'codigo': 'EMP-011',
        'nombres': 'Diego',
        'apellido_paterno': 'Roca',
        'apellido_materno': 'Suárez',
      },
      'cargo': {'id': 'c3', 'nombre': 'Analista contable'},
      'asistencia': {
        'fecha': '2026-10-24',
        'hora_entrada': '07:00:00',
        'hora_salida': '13:05:00',
        'horas_trabajadas': 6.08,
        'estado': 'PRESENTE',
      },
    },
    {
      'empleado': {
        'id': 'e14',
        'codigo': 'EMP-014',
        'nombres': 'Julia',
        'apellido_paterno': 'Quispe',
      },
      'cargo': {'id': 'c4', 'nombre': 'Tesorera'},
      // De vacaciones: la marca existe pero sin horas.
      'asistencia': {'fecha': '2026-10-24', 'estado': 'VACACION'},
    },
    {
      'empleado': {
        'id': 'e13',
        'codigo': 'EMP-013',
        'nombres': 'Pablo',
        'apellido_paterno': 'Arias',
      },
      'cargo': {'id': 'c5', 'nombre': 'Practicante'},
      'asistencia': {
        'fecha': '2026-10-24',
        'hora_entrada': '08:00:00',
        'hora_salida': null,
        'estado': 'PRESENTE',
      },
    },
  ];

  @override
  Future<List<MiembroEquipo>> miEquipo() async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 800));
    return datos.map(MiembroEquipo.fromJson).toList()
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
  }
}

/// El jefe todavía no tiene a nadie a su cargo.
class EquipoServiceVacio extends EquipoService {
  EquipoServiceVacio() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<MiembroEquipo>> miEquipo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [];
  }
}

/// Lanza un error de red: para la captura del estado "con error".
class EquipoServiceError extends EquipoService {
  EquipoServiceError() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<MiembroEquipo>> miEquipo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException(
      'No se pudo cargar tu equipo. '
      'Revisa tu conexión e inténtalo de nuevo.',
      statusCode: 503,
    );
  }
}

/// La cuenta no es jefe directo de nadie: 403.
class EquipoServiceSinPermiso extends EquipoService {
  EquipoServiceSinPermiso() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<MiembroEquipo>> miEquipo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException('Sin permiso.', statusCode: 403);
  }
}
