import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Servicios FALSOS para desarrollar sin backend, igual que en las otras
/// features. Aquí sirven además para trabajar sin estar autenticado.
///
/// Para las capturas de evidencia:
///   con pendientes  -> AprobacionesServiceFalso
///   bandeja vacía   -> AprobacionesServiceVacio
///   con error       -> AprobacionesServiceError
///   sesión expirada -> AprobacionesServiceSinSesion

/// Las dependencias reales no se usan en los fakes, pero el constructor de
/// AprobacionesService las pide. Se les pasa una instancia inerte.
AppHttpClient _clienteInerte() => AppHttpClient(baseUrl: 'falso');

/// Tres solicitudes pendientes, adrede DESORDENADAS.
///
/// Guarda las respuestas en memoria: al aprobar o rechazar, la solicitud
/// desaparece de la bandeja de verdad, como pasaría con el backend.
class AprobacionesServiceFalso extends AprobacionesService {
  AprobacionesServiceFalso() : super(_clienteInerte(), MemoryTokenStorage());

  /// Estado vivo de la bandeja, por id.
  final Map<String, Map<String, dynamic>> _bandeja = {
    '41': _vacacion(),
    '42': _bajaMedica(),
    '43': _permiso(),
  };

  @override
  Future<List<SolicitudAusencia>> pendientes() async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 800));

    final lista =
        _bandeja.values
            .map(SolicitudAusencia.fromJson)
            .where((s) => s.estaPendiente)
            .toList()
          ..sort(AprobacionesService.masAntiguaPrimero);

    return lista;
  }

  @override
  Future<SolicitudAusencia> detalle(String solicitudId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final crudo = _bandeja[solicitudId];
    if (crudo == null) {
      throw const AppException('La solicitud ya no existe.', statusCode: 404);
    }
    return SolicitudAusencia.fromJson(crudo);
  }

  @override
  Future<SolicitudAusencia> aprobar(String solicitudId, {String? observacion}) =>
      _responder(solicitudId, 'aprobada', observacion);

  @override
  Future<SolicitudAusencia> rechazar(
    String solicitudId, {
    required String observacion,
  }) {
    if (observacion.trim().isEmpty) {
      throw const AppException(
        'Para rechazar una solicitud hay que explicar el motivo.',
      );
    }
    return _responder(solicitudId, 'rechazada', observacion);
  }

  Future<SolicitudAusencia> _responder(
    String solicitudId,
    String nuevoEstado,
    String? observacion,
  ) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final crudo = _bandeja[solicitudId];
    if (crudo == null) {
      throw const AppException('La solicitud ya no existe.', statusCode: 404);
    }

    // Lo mismo que haría el backend si otro jefe respondió antes.
    if (SolicitudAusencia.parseEstado(crudo['estado']?.toString()) !=
        EstadoSolicitud.pendiente) {
      throw const AppException(
        'Otra persona ya respondió esta solicitud.',
        statusCode: 409,
      );
    }

    final limpia = observacion?.trim() ?? '';
    final actualizada = {
      ...crudo,
      'estado': nuevoEstado,
      if (limpia.isNotEmpty) 'observacion_aprobador': limpia,
      'fecha_respuesta': '2026-08-29T10:15:00',
    };
    _bandeja[solicitudId] = actualizada;

    return SolicitudAusencia.fromJson(actualizada);
  }

  // -------------------------------------------------------- las solicitudes

  /// Descuenta vacación y NO le alcanza el saldo: 5 días pedidos, 3 de
  /// saldo. Es el caso que justifica enseñarle el saldo al jefe.
  static Map<String, dynamic> _vacacion() => {
    'id': 41,
    'empresa_id': 1,
    'empleado_id': 7,
    'tipo_ausencia_id': 1,
    'fecha_inicio': '2026-09-12',
    'fecha_fin': '2026-09-16',
    'dias_solicitados': 5,
    'motivo': 'Viaje familiar programado desde hace meses.',
    'estado': 'pendiente',
    'fecha_solicitud': '2026-08-25T09:12:00',
    'empleado': {
      'nombres': 'Julia',
      'apellidos': 'Quispe',
      'cargo': 'Desarrolladora Backend',
    },
    'tipo_ausencia': {
      'id': 1,
      'nombre': 'Vacación',
      'codigo': 'VAC',
      'es_remunerado': true,
      'descuenta_vacacion': true,
      'dias_maximos_anio': 15,
      'requiere_aprobacion': true,
      'requiere_documento': false,
      'activo': true,
    },
    'saldo_vacacion': {
      'id': 5,
      'empleado_id': 7,
      'gestion': 2026,
      'dias_asignados': 15,
      'dias_usados': 12,
      'dias_saldo': 3,
      'fecha_corte': '2026-08-31',
    },
  };

  /// Exige documento y NO lo trae: el jefe tiene que verlo antes de aprobar.
  static Map<String, dynamic> _bajaMedica() => {
    'id': 42,
    'empresa_id': 1,
    'empleado_id': 9,
    'tipo_ausencia_id': 2,
    'fecha_inicio': '2026-09-01',
    'fecha_fin': '2026-09-03',
    'dias_solicitados': 3,
    'motivo': 'Reposo indicado por el médico.',
    'estado': 'pendiente',
    'fecha_solicitud': '2026-08-24T16:40:00',
    'empleado': {
      'nombres': 'Marco',
      'apellidos': 'Terceros',
      'cargo': 'Auxiliar Contable',
    },
    'tipo_ausencia': {
      'id': 2,
      'nombre': 'Baja médica',
      'codigo': 'MED',
      'es_remunerado': true,
      'descuenta_vacacion': false,
      'requiere_aprobacion': true,
      'requiere_documento': true,
      'activo': true,
    },
  };

  /// Un solo día, no remunerado, con documento adjunto.
  static Map<String, dynamic> _permiso() => {
    'id': 43,
    'empresa_id': 1,
    'empleado_id': 11,
    'tipo_ausencia_id': 3,
    'fecha_inicio': '2026-09-08',
    'fecha_fin': '2026-09-08',
    'dias_solicitados': 1,
    'motivo': 'Trámite personal en el SEGIP.',
    'documento_url': 'https://ejemplo.test/documentos/permiso-43.pdf',
    'estado': 'pendiente',
    'fecha_solicitud': '2026-08-26T11:05:00',
    'empleado': {
      'nombres': 'Renata',
      'apellidos': 'Suárez',
      'cargo': 'Analista de RRHH',
    },
    'tipo_ausencia': {
      'id': 3,
      'nombre': 'Permiso personal',
      'codigo': 'PER',
      'es_remunerado': false,
      'descuenta_vacacion': false,
      'requiere_aprobacion': true,
      'requiere_documento': true,
      'activo': true,
    },
  };
}

/// El jefe no tiene nada pendiente.
class AprobacionesServiceVacio extends AprobacionesService {
  AprobacionesServiceVacio() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<SolicitudAusencia>> pendientes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [];
  }
}

/// Lanza un error de red: para la captura del estado "con error".
class AprobacionesServiceError extends AprobacionesService {
  AprobacionesServiceError() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<SolicitudAusencia>> pendientes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException(
      'No se pudo completar la operación. '
      'Revisa tu conexión e inténtalo de nuevo.',
      statusCode: 503,
    );
  }
}

/// La sesión caducó: 401.
class AprobacionesServiceSinSesion extends AprobacionesService {
  AprobacionesServiceSinSesion()
    : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<SolicitudAusencia>> pendientes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException('No autenticado.', statusCode: 401);
  }
}
