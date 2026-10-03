import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/model/seguimiento_postulacion.dart';

/// Servicios FALSOS para desarrollar sin backend, igual que en vacantes.
///
/// Sirven para dos cosas:
///   1. Construir y ver la pantalla mientras el endpoint real no existe
///      (y en T2-18 todavía ni siquiera está definido en rrhh-api).
///   2. Sacar las 3 capturas de evidencia:
///        - con datos            -> SeguimientoServiceFalso
///        - código no encontrado -> SeguimientoServiceVacio
///        - con error            -> SeguimientoServiceError
///
/// Cuando el backend esté listo, vuelves a usar SeguimientoService normal.
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Devuelve la postulación de ejemplo de la maqueta: tres etapas recorridas
/// y dos por venir. Usa los MISMOS nombres de campo del diagrama de clases,
/// para que al cambiar al backend real no falle nada.
class SeguimientoServiceFalso extends SeguimientoService {
  SeguimientoServiceFalso() : super(baseUrl: 'falso');

  @override
  Future<SeguimientoPostulacion?> porCodigo(String codigo) async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 800));

    return SeguimientoPostulacion.fromJson({
      'id': 41,
      'codigo_seguimiento': codigo,
      'vacante_titulo': 'Desarrollador Backend',
      'empresa_nombre': 'Textiles del Oriente',
      'estado': 'en_proceso',
      'puntaje_ia': 81,
      'fecha_postulacion': '2026-08-20T14:02:00',
      'fecha_ultimo_cambio': '2026-08-26T10:00:00',
      'etapas': [
        {
          'id': 1,
          'nombre': 'Postulación recibida',
          'orden': 1,
          'es_inicial': true,
          'alcanzada': true,
          'fecha': '2026-08-20T14:02:00',
        },
        {
          'id': 2,
          'nombre': 'Preselección',
          'orden': 2,
          'alcanzada': true,
          // Sin hora: el backend registró solo el día.
          'fecha': '2026-08-22T00:00:00',
          'detalle': 'afinidad IA 81%',
        },
        {
          'id': 3,
          'nombre': 'Entrevista programada',
          'orden': 3,
          'alcanzada': true,
          'fecha': '2026-08-26T10:00:00',
          'detalle': 'virtual',
        },
        {'id': 4, 'nombre': 'Oferta', 'orden': 4, 'alcanzada': false},
        {
          'id': 5,
          'nombre': 'Contratado',
          'orden': 5,
          'es_contratado': true,
          'alcanzada': false,
        },
      ],
    });
  }
}

/// Devuelve null: el código no corresponde a ninguna postulación.
/// Para la captura del estado "código no encontrado".
class SeguimientoServiceVacio extends SeguimientoService {
  SeguimientoServiceVacio() : super(baseUrl: 'falso');

  @override
  Future<SeguimientoPostulacion?> porCodigo(String codigo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }
}

/// Lanza un error de red: para la captura del estado "con error".
class SeguimientoServiceError extends SeguimientoService {
  SeguimientoServiceError() : super(baseUrl: 'falso');

  @override
  Future<SeguimientoPostulacion?> porCodigo(String codigo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw SeguimientoException(
      503,
      'No se pudo consultar tu postulación. '
      'Revisa tu conexión e inténtalo de nuevo.',
    );
  }
}
