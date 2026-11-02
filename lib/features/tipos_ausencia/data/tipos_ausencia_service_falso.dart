import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend (T3-30).
///
/// Igual que en el resto del Sprint 3: no reemplazan ningún método, le
/// pasan a TiposAusenciaService un backend falso que responde con filas de
/// la tabla "tipo_ausencia" del diagrama.
///
/// El backend falso RECUERDA lo que se guarda mientras la pantalla está
/// abierta: al volver a la lista se ve el cambio, como con el backend real.
///
/// Para las capturas de evidencia:
///   con tipos (y uno inactivo) -> TiposAusenciaServiceFalso
///   sin tipos                  -> TiposAusenciaServiceVacio
///   con error                  -> TiposAusenciaServiceError
///   falla al guardar           -> TiposAusenciaServiceErrorAlGuardar
///   sesión expirada            -> TiposAusenciaServiceSinSesion
///   no es administrador        -> TiposAusenciaServiceSinPermiso
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Los tipos de la empresa: tres activos y uno desactivado. Se pueden editar.
class TiposAusenciaServiceFalso extends TiposAusenciaService {
  TiposAusenciaServiceFalso()
    : super(clienteFalso(_BackendTipos().responder), sesionFalsa());
}

/// La empresa todavía no configuró ningún tipo.
class TiposAusenciaServiceVacio extends TiposAusenciaService {
  TiposAusenciaServiceVacio()
    : super(
        clienteFalso(
          (_) => const <Object>[],
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red al cargar: para la captura del estado "con error".
class TiposAusenciaServiceError extends TiposAusenciaService {
  TiposAusenciaServiceError()
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

/// Carga bien, pero falla al guardar: el formulario no pierde lo escrito.
class TiposAusenciaServiceErrorAlGuardar extends TiposAusenciaService {
  TiposAusenciaServiceErrorAlGuardar()
    : super(
        clienteFalso((p) {
          if (p.metodo == 'PUT') {
            throw const ErrorFalso(
              503,
              'No se pudieron guardar los cambios. '
              'Inténtalo de nuevo en unos minutos.',
            );
          }
          return _BackendTipos().responder(p);
        }),
        sesionFalsa(),
      );
}

/// La sesión caducó: 401.
class TiposAusenciaServiceSinSesion extends TiposAusenciaService {
  TiposAusenciaServiceSinSesion()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(401, 'No autenticado.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Un colaborador sin el permiso ausencias:gestionar: 403.
class TiposAusenciaServiceSinPermiso extends TiposAusenciaService {
  TiposAusenciaServiceSinPermiso()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(403, 'Permiso insuficiente.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Un backend con memoria: GET devuelve las filas y PUT las reemplaza,
/// con las mismas validaciones que la tabla (código único por empresa).
class _BackendTipos {
  final _filas = [for (final t in _tipos) Map<String, Object?>.of(t)];

  Object? responder(PeticionFalsa p) {
    if (p.es('GET', '/personal/tipos-ausencia')) return _filas;

    const prefijo = '/personal/tipos-ausencia/';
    if (p.metodo == 'PUT' && p.ruta.startsWith(prefijo)) {
      final id = p.ruta.substring(prefijo.length);
      final i = _filas.indexWhere((f) => f['id'] == id);
      if (i == -1) {
        throw const ErrorFalso(404, 'Tipo de ausencia no encontrado.');
      }

      final cuerpo = p.cuerpo ?? const {};
      final codigo = cuerpo['codigo'];
      final repetido = _filas.any(
        (f) => f['id'] != id && f['codigo'] == codigo,
      );
      if (repetido) {
        throw ErrorFalso(
          409,
          'Ya existe un tipo de ausencia con el código '
          '$codigo.',
        );
      }
      return _filas[i] = {..._filas[i], ...cuerpo};
    }
    throw ErrorFalso.rutaDesconocida(p);
  }
}

// ----------------------------------------------------- tipo_ausencia (4)

/// Los mismos tipos de la solicitud y de la bandeja del jefe, más uno
/// desactivado, para mostrar cómo se ve y que se puede reactivar.
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
