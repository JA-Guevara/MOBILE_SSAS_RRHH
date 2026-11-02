import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend.
///
/// No reemplazan ningún método: le pasan a AprobacionesService un backend
/// falso que responde con filas de las tablas del diagrama del Sprint 3
/// (solicitud_ausencia, tipo_ausencia, saldo_vacacion), cada una por su
/// lado, más GET /empleados, que ya existe en rrhh-api. La unión por
/// tipo_ausencia_id y empleado_id la hace el servicio real.
///
/// Para las capturas de evidencia:
///   con pendientes  -> AprobacionesServiceFalso
///   bandeja vacía   -> AprobacionesServiceVacio
///   con error       -> AprobacionesServiceError
///   sesión expirada -> AprobacionesServiceSinSesion
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Tres solicitudes pendientes, adrede DESORDENADAS.
///
/// Guarda las respuestas en memoria: al aprobar o rechazar, la solicitud
/// cambia de estado y sale de la bandeja de verdad, como en el backend.
class AprobacionesServiceFalso extends AprobacionesService {
  AprobacionesServiceFalso() : this._(_BandejaFalsa());

  AprobacionesServiceFalso._(_BandejaFalsa bandeja)
    : super(clienteFalso(bandeja.responder), sesionFalsa());
}

class _BandejaFalsa {
  /// Estado vivo de solicitud_ausencia, por id.
  final Map<String, Map<String, dynamic>> _solicitudes = {
    for (final s in [_vacacion, _bajaMedica, _permiso])
      s['id'] as String: {...s},
  };

  Object? responder(PeticionFalsa p) {
    if (p.es('GET', '/solicitudes-ausencia/pendientes')) {
      return _solicitudes.values
          .where((s) => s['estado'] == 'PENDIENTE')
          .toList();
    }
    if (p.es('GET', '/tipos-ausencia')) return _tipos;
    if (p.es('GET', '/empleados')) return _empleados;
    if (p.es('GET', '/saldos-vacacion')) {
      final empleado = p.query['empleado_id'];
      return _saldos
          .where((s) => empleado == null || s['empleado_id'] == empleado)
          .toList();
    }

    for (final id in _solicitudes.keys) {
      if (p.es('GET', '/solicitudes-ausencia/$id')) return _solicitudes[id];
      if (p.es('POST', '/solicitudes-ausencia/$id/aprobar')) {
        return _responder(id, 'APROBADA', p.cuerpo);
      }
      if (p.es('POST', '/solicitudes-ausencia/$id/rechazar')) {
        return _responder(id, 'RECHAZADA', p.cuerpo);
      }
    }

    if (p.ruta.startsWith('/solicitudes-ausencia/')) {
      throw const ErrorFalso(404, 'La solicitud ya no existe.');
    }
    throw ErrorFalso.rutaDesconocida(p);
  }

  Map<String, dynamic> _responder(
    String id,
    String nuevoEstado,
    Map<String, dynamic>? cuerpo,
  ) {
    final fila = _solicitudes[id]!;

    // Lo mismo que haría el backend si otro jefe respondió antes.
    if (fila['estado'] != 'PENDIENTE') {
      throw const ErrorFalso(409, 'Otra persona ya respondió esta solicitud.');
    }

    return _solicitudes[id] = {
      ...fila,
      'estado': nuevoEstado,
      'aprobador_id': 'e1',
      'observacion_aprobador': cuerpo?['observacion_aprobador'],
      'fecha_respuesta': '2026-08-29T10:15:00',
    };
  }

  // ---------------------------------------------- solicitud_ausencia (3)

  /// Descuenta vacación y NO le alcanza el saldo: 5 días pedidos, 3 de
  /// saldo. Es el caso que justifica enseñarle el saldo al jefe.
  static const _vacacion = {
    'id': '41',
    'empresa_id': 'emp1',
    'empleado_id': 'e7',
    'tipo_ausencia_id': 't1',
    'aprobador_id': null,
    'fecha_inicio': '2026-09-12',
    'fecha_fin': '2026-09-16',
    'dias_solicitados': 5,
    'motivo': 'Viaje familiar programado desde hace meses.',
    'documento_url': null,
    'estado': 'PENDIENTE',
    'observacion_aprobador': null,
    'fecha_solicitud': '2026-08-25T09:12:00',
    'fecha_respuesta': null,
  };

  /// Exige documento y NO lo trae: el jefe tiene que verlo antes de aprobar.
  static const _bajaMedica = {
    'id': '42',
    'empresa_id': 'emp1',
    'empleado_id': 'e9',
    'tipo_ausencia_id': 't2',
    'aprobador_id': null,
    'fecha_inicio': '2026-09-01',
    'fecha_fin': '2026-09-03',
    'dias_solicitados': 3,
    'motivo': 'Reposo indicado por el médico.',
    'documento_url': null,
    'estado': 'PENDIENTE',
    'observacion_aprobador': null,
    'fecha_solicitud': '2026-08-24T16:40:00',
    'fecha_respuesta': null,
  };

  /// Un solo día, no remunerado, con documento adjunto.
  static const _permiso = {
    'id': '43',
    'empresa_id': 'emp1',
    'empleado_id': 'e11',
    'tipo_ausencia_id': 't3',
    'aprobador_id': null,
    'fecha_inicio': '2026-09-08',
    'fecha_fin': '2026-09-08',
    'dias_solicitados': 1,
    'motivo': 'Trámite personal en el SEGIP.',
    'documento_url': 'https://ejemplo.test/documentos/permiso-43.pdf',
    'estado': 'PENDIENTE',
    'observacion_aprobador': null,
    'fecha_solicitud': '2026-08-26T11:05:00',
    'fecha_respuesta': null,
  };

  // ---------------------------------------------------- tipo_ausencia (3)

  static const _tipos = [
    {
      'id': 't1',
      'empresa_id': 'emp1',
      'nombre': 'Vacación',
      'codigo': 'VAC',
      'es_remunerado': true,
      'descuenta_vacacion': true,
      'dias_maximos_anio': 15,
      'requiere_aprobacion': true,
      'requiere_documento': false,
      'activo': true,
    },
    {
      'id': 't2',
      'empresa_id': 'emp1',
      'nombre': 'Baja médica',
      'codigo': 'MED',
      'es_remunerado': true,
      'descuenta_vacacion': false,
      'dias_maximos_anio': null,
      'requiere_aprobacion': true,
      'requiere_documento': true,
      'activo': true,
    },
    {
      'id': 't3',
      'empresa_id': 'emp1',
      'nombre': 'Permiso personal',
      'codigo': 'PER',
      'es_remunerado': false,
      'descuenta_vacacion': false,
      'dias_maximos_anio': null,
      'requiere_aprobacion': true,
      'requiere_documento': true,
      'activo': true,
    },
  ];

  // --------------------------------------------------- saldo_vacacion (2)

  static const _saldos = [
    // Gestión anterior: el servicio tiene que quedarse con la más reciente.
    {
      'id': 's4',
      'empleado_id': 'e7',
      'gestion': 2025,
      'dias_asignados': 15,
      'dias_usados': 15,
      'dias_saldo': 0,
      'fecha_corte': '2025-12-31',
      'fecha_actualizacion': '2025-12-31T23:59:00',
    },
    {
      'id': 's5',
      'empleado_id': 'e7',
      'gestion': 2026,
      'dias_asignados': 15,
      'dias_usados': 12,
      'dias_saldo': 3,
      'fecha_corte': '2026-08-31',
      'fecha_actualizacion': '2026-08-31T18:00:00',
    },
  ];

  // ------------------------------- GET /empleados (endpoint que ya existe)

  static const _empleados = [
    {
      'id': 'e7',
      'empresa_id': 'emp1',
      'codigo': 'EMP-007',
      'nombres': 'Julia',
      'apellido_paterno': 'Quispe',
      'apellido_materno': null,
      'fecha_ingreso': '2024-02-01',
      'estado': 'ACTIVO',
    },
    {
      'id': 'e9',
      'empresa_id': 'emp1',
      'codigo': 'EMP-009',
      'nombres': 'Marco',
      'apellido_paterno': 'Terceros',
      'apellido_materno': null,
      'fecha_ingreso': '2023-05-15',
      'estado': 'ACTIVO',
    },
    {
      'id': 'e11',
      'empresa_id': 'emp1',
      'codigo': 'EMP-011',
      'nombres': 'Renata',
      'apellido_paterno': 'Suárez',
      'apellido_materno': null,
      'fecha_ingreso': '2025-01-06',
      'estado': 'ACTIVO',
    },
  ];
}

/// El jefe no tiene nada pendiente.
class AprobacionesServiceVacio extends AprobacionesService {
  AprobacionesServiceVacio()
    : super(
        clienteFalso(
          (p) => switch (p.ruta) {
            '/solicitudes-ausencia/pendientes' ||
            '/tipos-ausencia' ||
            '/empleados' ||
            '/saldos-vacacion' => const <Object>[],
            _ => throw ErrorFalso.rutaDesconocida(p),
          },
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red: para la captura del estado "con error".
class AprobacionesServiceError extends AprobacionesService {
  AprobacionesServiceError()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(
            503,
            'No se pudo completar la operación. '
            'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// La sesión caducó: 401.
class AprobacionesServiceSinSesion extends AprobacionesService {
  AprobacionesServiceSinSesion()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(401, 'No autenticado.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}
