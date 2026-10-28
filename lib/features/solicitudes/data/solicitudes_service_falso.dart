import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend (T3-19).
///
/// Igual que en el Sprint 3: no reemplazan ningún método, le pasan a
/// SolicitudesService un backend falso que responde con filas de las tablas
/// tipo_ausencia, saldo_vacacion y solicitud_ausencia del diagrama.
///
/// Los datos son los de Julia Quispe en la bandeja del jefe (T3-22): mismo
/// saldo de 3 de 15 días en 2026. Así, si pide 5 días de vacación, ve el
/// mismo aviso de saldo insuficiente que verá su jefe.
///
/// El backend falso valida el envío con las mismas reglas que tendrá
/// rrhh-api (saldo, documento obligatorio), para que el 422 se pueda ver.
///
/// Para las capturas de evidencia:
///   formulario            -> SolicitudesServiceFalso
///   sin saldo             -> SolicitudesServiceSinSaldo
///   sin tipos             -> SolicitudesServiceVacio
///   con error al cargar   -> SolicitudesServiceError
///   sesión expirada       -> SolicitudesServiceSinSesion
///   con error al enviar   -> SolicitudesServiceErrorAlEnviar
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Tres tipos activos (más uno inactivo que no debe salir) y el saldo.
class SolicitudesServiceFalso extends SolicitudesService {
  SolicitudesServiceFalso()
    : super(clienteFalso(_BackendSolicitudes().responder), sesionFalsa());
}

/// Todavía no tiene vacaciones asignadas: el backend responde 404.
class SolicitudesServiceSinSaldo extends SolicitudesService {
  SolicitudesServiceSinSaldo()
    : super(
        clienteFalso(_BackendSolicitudes(conSaldo: false).responder),
        sesionFalsa(),
      );
}

/// Carga bien, pero el envío falla por la red: el formulario no se pierde.
class SolicitudesServiceErrorAlEnviar extends SolicitudesService {
  SolicitudesServiceErrorAlEnviar()
    : super(
        clienteFalso(_BackendSolicitudes(falloAlEnviar: true).responder),
        sesionFalsa(),
      );
}

/// La empresa no configuró ningún tipo de ausencia.
class SolicitudesServiceVacio extends SolicitudesService {
  SolicitudesServiceVacio()
    : super(
        clienteFalso(
          (p) => switch (p.ruta) {
            '/tipos-ausencia' => const <Object>[],
            '/saldos-vacacion/mio' => _saldos,
            _ => throw ErrorFalso.rutaDesconocida(p),
          },
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red: para la captura del estado "con error".
class SolicitudesServiceError extends SolicitudesService {
  SolicitudesServiceError()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(
            503,
            'No se pudieron cargar los tipos de ausencia. '
            'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// La sesión caducó: 401.
class SolicitudesServiceSinSesion extends SolicitudesService {
  SolicitudesServiceSinSesion()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(401, 'No autenticado.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// El backend de Julia: responde las lecturas y valida el envío.
class _BackendSolicitudes {
  final bool conSaldo;
  final bool falloAlEnviar;

  _BackendSolicitudes({this.conSaldo = true, this.falloAlEnviar = false});

  Object? responder(PeticionFalsa p) {
    if (p.es('GET', '/tipos-ausencia')) return _tipos;
    if (p.es('GET', '/saldos-vacacion/mio')) {
      if (!conSaldo) throw const ErrorFalso(404, 'Sin saldo de vacaciones.');
      return _saldos;
    }
    if (p.es('POST', '/solicitudes-ausencia')) return _crear(p);
    throw ErrorFalso.rutaDesconocida(p);
  }

  /// Las mismas reglas que tendrá rrhh-api al registrar la solicitud.
  Map<String, Object?> _crear(PeticionFalsa p) {
    if (falloAlEnviar) {
      throw const ErrorFalso(
        503,
        'No se pudo enviar la solicitud. '
        'Revisa tu conexión e inténtalo de nuevo.',
      );
    }

    final c = p.campos;
    final tipo = _tipos.where((t) => t['id'] == c['tipo_ausencia_id']);
    if (tipo.isEmpty || tipo.first['activo'] != true) {
      throw const ErrorFalso(422, 'El tipo de ausencia no es válido.');
    }
    final dias = int.tryParse(c['dias_solicitados'] ?? '') ?? 0;

    // El saldo nunca queda negativo (caso 4 de T3-23).
    if (tipo.first['descuenta_vacacion'] == true) {
      final saldo = conSaldo ? _saldos.last['dias_saldo'] as int : 0;
      if (dias > saldo) {
        throw ErrorFalso(
          422,
          'Saldo insuficiente: tienes $saldo días y pides $dias.',
        );
      }
    }

    final documento = p.archivos['documento'];
    if (tipo.first['requiere_documento'] == true && documento == null) {
      throw const ErrorFalso(
        422,
        'Este tipo de ausencia exige un documento de respaldo.',
      );
    }

    return {
      'id': 'sol-nueva',
      'empresa_id': 'emp1',
      'empleado_id': 'e7',
      'tipo_ausencia_id': c['tipo_ausencia_id'],
      'aprobador_id': null,
      'fecha_inicio': c['fecha_inicio'],
      'fecha_fin': c['fecha_fin'],
      'dias_solicitados': dias,
      'motivo': c['motivo'],
      'documento_url': documento == null
          ? null
          : 'https://falso/documentos/${documento.nombre}',
      'estado': 'PENDIENTE',
      'observacion_aprobador': null,
      'fecha_solicitud': DateTime.now().toIso8601String(),
      'fecha_respuesta': null,
    };
  }
}

// ----------------------------------------------------- tipo_ausencia (4)

/// Los mismos tres tipos de la bandeja del jefe, más uno inactivo.
const _tipos = [
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
  // Desactivado por la empresa: no se puede pedir y no debe aparecer.
  {
    'id': 't4',
    'empresa_id': 'emp1',
    'nombre': 'Licencia por estudios',
    'codigo': 'EST',
    'es_remunerado': false,
    'descuenta_vacacion': false,
    'dias_maximos_anio': 10,
    'requiere_aprobacion': true,
    'requiere_documento': true,
    'activo': false,
  },
];

// ---------------------------------------------------- saldo_vacacion (2)

const _saldos = [
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
