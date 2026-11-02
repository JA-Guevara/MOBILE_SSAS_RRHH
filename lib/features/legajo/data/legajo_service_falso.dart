import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/backend_falso.dart';

/// Servicios FALSOS para desarrollar sin backend. En T3-27 son
/// OBLIGATORIOS por ahora: el backend no tiene documento_empleado (T3-01 y
/// T3-02 sin construir).
///
/// No reemplazan ningún método: le pasan a LegajoService un backend falso
/// que responde con filas de "documento_empleado". Corre el mismo código
/// que contra rrhh-api.
///
/// Para las capturas de evidencia:
///   con documentos -> LegajoServiceFalso
///   vacío          -> LegajoServiceVacio
///   con error      -> LegajoServiceError
///   sesión vencida -> LegajoServiceSinSesion
///
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Seis documentos que cubren los cuatro casos de vigencia, adrede
/// DESORDENADOS para comprobar que la pantalla los ordena por urgencia.
///
/// Las fechas se calculan desde hoy: así la captura siempre muestra un
/// documento vencido y dos por vencer, sin importar el día en que se tome.
class LegajoServiceFalso extends LegajoService {
  LegajoServiceFalso()
    : super(
        clienteFalso(
          (p) => p.es('GET', '/documentos-empleado/mios')
              ? datos(DateTime.now())
              : throw ErrorFalso.rutaDesconocida(p),
        ),
        sesionFalsa(),
      );

  /// Mismas claves que lee DocumentoEmpleado.fromJson, para que al cambiar
  /// al backend real no falle nada.
  static List<Map<String, dynamic>> datos(DateTime hoy) => [
    {
      'id': 'd1',
      'empleado_id': 'e7',
      'tipo': 'TITULO',
      'nombre': 'Título de Licenciatura en Contaduría',
      'archivo_url': 'https://archivos.ssah.test/legajo/titulo.pdf',
      'fecha_emision': '2019-12-13',
      'fecha_vencimiento': null,
      'fecha_carga': '2026-09-24T10:12:00',
    },
    {
      'id': 'd2',
      'empleado_id': 'e7',
      'tipo': 'EXAMEN_MEDICO',
      'nombre': 'Examen médico preocupacional',
      'archivo_url': 'https://archivos.ssah.test/legajo/examen.pdf',
      'fecha_emision': _iso(hoy, -350),
      'fecha_vencimiento': _iso(hoy, 12),
      'fecha_carga': '2026-09-24T10:15:00',
    },
    {
      'id': 'd3',
      'empleado_id': 'e7',
      'tipo': 'CI',
      'nombre': 'Carnet de identidad',
      'archivo_url': 'https://archivos.ssah.test/legajo/ci.pdf',
      'fecha_emision': '2021-04-08',
      'fecha_vencimiento': _iso(hoy, 900),
      'fecha_carga': '2026-09-24T10:10:00',
    },
    {
      'id': 'd4',
      'empleado_id': 'e7',
      'tipo': 'ANTECEDENTES',
      'nombre': 'Certificado de antecedentes (REJAP)',
      'archivo_url': 'https://archivos.ssah.test/legajo/rejap.pdf',
      'fecha_emision': _iso(hoy, -185),
      'fecha_vencimiento': _iso(hoy, -5),
      'fecha_carga': '2026-09-24T10:20:00',
    },
    {
      'id': 'd5',
      'empleado_id': 'e7',
      'tipo': 'CONTRATO',
      'nombre': 'Contrato de trabajo indefinido',
      'archivo_url': 'https://archivos.ssah.test/legajo/contrato.pdf',
      'fecha_emision': '2026-09-22',
      'fecha_vencimiento': null,
      'fecha_carga': '2026-09-24T10:25:00',
    },
    {
      'id': 'd6',
      'empleado_id': 'e7',
      'tipo': 'CERTIFICADO',
      'nombre': 'Certificado de primeros auxilios',
      // Sin archivo cargado todavía: la tarjeta no ofrece "Ver archivo".
      'archivo_url': null,
      'fecha_emision': _iso(hoy, -340),
      'fecha_vencimiento': _iso(hoy, 25),
      'fecha_carga': '2026-09-24T10:30:00',
    },
  ];
}

/// El colaborador todavía no tiene documentos cargados.
class LegajoServiceVacio extends LegajoService {
  LegajoServiceVacio()
    : super(
        clienteFalso(
          (_) => const <Object>[],
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// Lanza un error de red: para la captura del estado "con error".
class LegajoServiceError extends LegajoService {
  LegajoServiceError()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(
            503,
            'No se pudieron cargar tus documentos. '
            'Revisa tu conexión e inténtalo de nuevo.',
          ),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// La sesión caducó: 401.
class LegajoServiceSinSesion extends LegajoService {
  LegajoServiceSinSesion()
    : super(
        clienteFalso(
          (_) => throw const ErrorFalso(401, 'No autenticado.'),
          demora: const Duration(milliseconds: 500),
        ),
        sesionFalsa(),
      );
}

/// "2026-11-05": la fecha a [dias] de [hoy], como la manda una columna DATE.
String _iso(DateTime hoy, int dias) {
  final f = DateTime(hoy.year, hoy.month, hoy.day + dias);
  final mm = f.month.toString().padLeft(2, '0');
  final dd = f.day.toString().padLeft(2, '0');
  return '${f.year}-$mm-$dd';
}
