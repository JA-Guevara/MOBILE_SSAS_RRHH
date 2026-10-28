import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend (T3-28).
///
/// Igual que en el Sprint 3: no reemplazan ningún método, le pasan a
/// MiContratoService un backend falso que responde con filas de la tabla
/// "contrato" del diagrama y con GET /cargos, que ya existe en rrhh-api.
///
/// Son los contratos de Julia Quispe (ingresó el 01/02/2024): hoy gana
/// Bs 9.800, el mismo salario de su boleta y de la demo del sprint. Las
/// versiones van ADREDE desordenadas, para comprobar que la pantalla ordena.
///
/// Para las capturas de evidencia:
///   vigente + historial   -> MiContratoServiceFalso
///   primer contrato       -> MiContratoServicePrimerContrato
///   sin contrato vigente  -> MiContratoServiceFinalizado
///   sin contratos         -> MiContratoServiceVacio
///   con error             -> MiContratoServiceError
///   sesión expirada       -> MiContratoServiceSinSesion
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// El vigente y dos versiones anteriores.
class MiContratoServiceFalso extends MiContratoService {
  MiContratoServiceFalso()
    : super(
        clienteFalso(_responder([_renovacion, _ascenso, _inicial])),
        sesionFalsa(),
      );
}

/// Recién contratada: un solo contrato, sin versiones anteriores.
class MiContratoServicePrimerContrato extends MiContratoService {
  MiContratoServicePrimerContrato()
    : super(
        clienteFalso(
          _responder([
            {..._inicial, 'estado': 'VIGENTE', 'fecha_fin': null},
          ]),
        ),
        sesionFalsa(),
      );
}

/// Su último contrato ya terminó: no hay vigente, pero sí historial.
class MiContratoServiceFinalizado extends MiContratoService {
  MiContratoServiceFinalizado()
    : super(
        clienteFalso(
          _responder([
            {..._ascenso, 'estado': 'FINALIZADO', 'fecha_fin': '2026-09-30'},
            _renovacion,
            _inicial,
          ]),
        ),
        sesionFalsa(),
      );
}

/// Todavía no tiene ningún contrato registrado.
class MiContratoServiceVacio extends MiContratoService {
  MiContratoServiceVacio()
    : super(
        clienteFalso(
          _responder(const []),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red: para la captura del estado "con error".
class MiContratoServiceError extends MiContratoService {
  MiContratoServiceError()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(
            503,
            'No se pudo cargar tu contrato. '
            'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// La sesión caducó: 401.
class MiContratoServiceSinSesion extends MiContratoService {
  MiContratoServiceSinSesion()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(401, 'No autenticado.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

Object? Function(PeticionFalsa) _responder(List<Map<String, Object?>> filas) =>
    (p) => switch (p.ruta) {
      '/contratos/mios' => filas,
      '/cargos' => _cargos,
      _ => throw ErrorFalso.rutaDesconocida(p),
    };

// ------------------------------------------------------------ contrato (3)

/// El primero: a plazo fijo, como desarrolladora junior.
const _inicial = <String, Object?>{
  'id': 'c7-1',
  'empresa_id': 'emp1',
  'empleado_id': 'e7',
  'cargo_id': 'g1',
  'departamento_id': 'd1',
  'jefe_directo_id': 'e2',
  'contrato_anterior_id': null,
  'numero_contrato': 'CTR-2024-007',
  'tipo_contrato': 'PLAZO_FIJO',
  'modalidad': 'PRESENCIAL',
  'jornada': 'TIEMPO_COMPLETO',
  'salario_basico': '7000.00',
  'moneda': 'BOB',
  'fecha_inicio': '2024-02-01',
  'fecha_fin': '2025-01-31',
  'motivo_cambio': null,
  'documento_url': null,
  'estado': 'FINALIZADO',
  'fecha_registro': '2024-01-25T10:00:00',
};

/// Renovación: pasa a indefinido, con aumento.
final _renovacion = <String, Object?>{
  ..._inicial,
  'id': 'c7-2',
  'contrato_anterior_id': 'c7-1',
  'numero_contrato': 'CTR-2025-007',
  'tipo_contrato': 'INDEFINIDO',
  'salario_basico': '8200.00',
  'fecha_inicio': '2025-02-01',
  'fecha_fin': '2026-03-31',
  'motivo_cambio': 'Renovación a plazo indefinido',
  'estado': 'FINALIZADO',
  'fecha_registro': '2025-01-28T09:30:00',
};

/// El vigente: ascenso a Desarrollador Backend, con modalidad híbrida.
final _ascenso = <String, Object?>{
  ..._renovacion,
  'id': 'c7-3',
  'cargo_id': 'g2',
  'contrato_anterior_id': 'c7-2',
  'numero_contrato': 'CTR-2026-007',
  'modalidad': 'HIBRIDO',
  'salario_basico': '9800.00',
  'fecha_inicio': '2026-04-01',
  'fecha_fin': null,
  'motivo_cambio': 'Ascenso a Desarrollador Backend',
  'estado': 'VIGENTE',
  'fecha_registro': '2026-03-25T16:00:00',
};

// --------------------------------- GET /cargos (endpoint que ya existe)

const _cargos = [
  {'id': 'g1', 'nombre': 'Desarrollador Junior'},
  {'id': 'g2', 'nombre': 'Desarrollador Backend'},
];
