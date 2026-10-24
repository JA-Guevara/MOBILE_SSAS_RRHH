import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend. En T3-29 son
/// OBLIGATORIOS por ahora: el backend no tiene contrato (T3-01) ni
/// asistencia (T3-05).
///
/// No reemplazan ningún método: le pasan a EquipoService un backend falso
/// que responde con filas de "contrato" y "asistencia" del diagrama del
/// Sprint 3, más GET /empleados y GET /cargos, que ya existen en rrhh-api.
/// La unión por empleado_id y cargo_id la hace el servicio real.
///
/// Para las capturas de evidencia:
///   con equipo     -> EquipoServiceFalso
///   vacío          -> EquipoServiceVacio
///   con error      -> EquipoServiceError
///   no es jefe     -> EquipoServiceSinPermiso
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Seis personas que cubren los cuatro estados del día, adrede
/// DESORDENADAS para comprobar que la lista sale por nombre. Hay además un
/// contrato FINALIZADO que no debe aparecer.
class EquipoServiceFalso extends EquipoService {
  EquipoServiceFalso() : super(clienteFalso(_responder), sesionFalsa());

  static Object? _responder(PeticionFalsa p) {
    if (p.es('GET', '/contratos/mi-equipo')) return contratos;
    if (p.es('GET', '/asistencias')) return asistencias;
    if (p.es('GET', '/empleados')) return empleados;
    if (p.es('GET', '/cargos')) return cargos;
    throw ErrorFalso.rutaDesconocida(p);
  }

  // ------------------------------------------------------- contrato (7)

  static final contratos = [
    _contrato('c12', 'e12', 'g3'),
    _contrato('c10', 'e10', 'g2'),
    _contrato('c15', 'e15', 'g6'),
    _contrato('c11', 'e11', 'g3'),
    _contrato('c14', 'e14', 'g4'),
    _contrato('c13', 'e13', 'g5', tipo: 'PASANTIA'),
    // Contrato anterior de Marco, cerrado por un ascenso: no cuenta.
    _contrato('c09', 'e12', 'g6', estado: 'FINALIZADO'),
  ];

  /// Una fila de contrato con TODAS sus columnas.
  static Map<String, dynamic> _contrato(
    String id,
    String empleadoId,
    String cargoId, {
    String tipo = 'INDEFINIDO',
    String estado = 'VIGENTE',
  }) => {
    'id': id,
    'empresa_id': 'emp1',
    'empleado_id': empleadoId,
    'cargo_id': cargoId,
    'departamento_id': 'd1',
    'jefe_directo_id': 'e1',
    'contrato_anterior_id': null,
    'numero_contrato': 'CTR-2026-${id.substring(1)}',
    'tipo_contrato': tipo,
    'modalidad': 'PRESENCIAL',
    'jornada': 'TIEMPO_COMPLETO',
    'salario_basico': 6500,
    'moneda': 'BOB',
    'fecha_inicio': '2026-01-02',
    'fecha_fin': null,
    'motivo_cambio': null,
    'documento_url': null,
    'estado': estado,
    'fecha_registro': '2026-01-02T09:00:00',
  };

  // ------------------------------------------- asistencia de hoy (5 filas)

  /// Rosa (e15) no tiene fila: todavía no marcó.
  static final asistencias = [
    _asistencia('e12', entrada: '08:12:00', retraso: 12, estado: 'TARDANZA'),
    _asistencia('e10', entrada: '07:56:00', retraso: 0, estado: 'PRESENTE'),
    _asistencia(
      'e11',
      entrada: '07:00:00',
      salida: '13:05:00',
      horas: 6.08,
      estado: 'PRESENTE',
    ),
    // De vacaciones: la fila existe pero sin horas.
    _asistencia('e14', estado: 'VACACION'),
    _asistencia('e13', entrada: '08:00:00', estado: 'PRESENTE'),
  ];

  /// Una fila de asistencia con TODAS sus columnas.
  static Map<String, dynamic> _asistencia(
    String empleadoId, {
    String? entrada,
    String? salida,
    double? horas,
    int? retraso,
    required String estado,
  }) => {
    'id': 'a-$empleadoId',
    'empleado_id': empleadoId,
    'fecha': '2026-10-24',
    'hora_entrada': entrada,
    'hora_salida': salida,
    'latitud_entrada': entrada == null ? null : -17.7833,
    'longitud_entrada': entrada == null ? null : -63.1821,
    'latitud_salida': salida == null ? null : -17.7834,
    'longitud_salida': salida == null ? null : -63.1822,
    'horas_trabajadas': horas,
    'horas_extra': null,
    'minutos_retraso': retraso,
    'origen': entrada == null ? 'MANUAL' : 'APP_MOVIL',
    'estado': estado,
    'observacion': null,
  };

  // ------------------------------- GET /empleados (endpoint que ya existe)

  static final empleados = [
    _empleado('e12', 'Marco', 'Terceros', 'Vaca'),
    _empleado('e10', 'Lucía', 'Fernández', 'Rojas'),
    _empleado('e15', 'Rosa', 'Mamani', null),
    _empleado('e11', 'Diego', 'Roca', 'Suárez'),
    _empleado('e14', 'Julia', 'Quispe', null),
    _empleado('e13', 'Pablo', 'Arias', null),
  ];

  static Map<String, dynamic> _empleado(
    String id,
    String nombres,
    String paterno,
    String? materno,
  ) => {
    'id': id,
    'empresa_id': 'emp1',
    'codigo': 'EMP-${id.substring(1).padLeft(3, '0')}',
    'nombres': nombres,
    'apellido_paterno': paterno,
    'apellido_materno': materno,
    'fecha_ingreso': '2026-01-02',
    'estado': 'ACTIVO',
  };

  // ---------------------------------- GET /cargos (endpoint que ya existe)

  static final cargos = [
    _cargo('g2', 'Asistente de RR. HH.'),
    _cargo('g3', 'Analista contable'),
    _cargo('g4', 'Tesorera'),
    _cargo('g5', 'Practicante'),
    _cargo('g6', 'Auxiliar contable'),
  ];

  static Map<String, dynamic> _cargo(String id, String nombre) => {
    'id': id,
    'empresa_id': 'emp1',
    'departamento_id': 'd1',
    'nombre': nombre,
    'activo': true,
  };
}

/// El jefe todavía no tiene a nadie a su cargo.
class EquipoServiceVacio extends EquipoService {
  EquipoServiceVacio()
    : super(
        clienteFalso(
          (_) => const <Object>[],
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red: para la captura del estado "con error".
class EquipoServiceError extends EquipoService {
  EquipoServiceError()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(
            503,
            'No se pudo cargar tu equipo. '
            'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// La cuenta no es jefe directo de nadie: 403.
class EquipoServiceSinPermiso extends EquipoService {
  EquipoServiceSinPermiso()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(403, 'Sin permiso.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}
