import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/postulante.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/resultado_postulacion.dart';


/// Servicios FALSOS para desarrollar sin backend, igual que en vacantes.
///
/// Sirven para dos cosas:
///   1. Construir y ver la pantalla mientras el endpoint real no existe.
///   2. Sacar las 3 capturas de evidencia:
///        - formulario vacío   -> no necesita servicio, es el estado inicial
///        - con datos / éxito  -> PostulacionesServiceFalso
///        - con error          -> PostulacionesServiceError
///
/// Cuando el backend esté listo, vuelves a usar PostulacionesService normal.
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Acepta la postulación y devuelve un código de seguimiento de ejemplo,
/// el mismo de la maqueta. Para la captura "con datos".

class PostulacionEstado {
  final String codigo;
  final String vacanteTitulo;
  final String etapaActual;
  final String estado;

  PostulacionEstado({
    required this.codigo,
    required this.vacanteTitulo,
    required this.etapaActual,
    required this.estado,
  });
}
class PostulacionesServiceFalso extends PostulacionesService {
  PostulacionesServiceFalso() : super(baseUrl: 'falso');

  @override
  Future<ResultadoPostulacion> postular({
    required String slug,
    required int vacanteId,
    required Postulante postulante,
    required CvAdjunto cv,
  }) async {
    // Simula la demora de la subida, para ver el estado "enviando".
    await Future.delayed(const Duration(milliseconds: 1200));

    return const ResultadoPostulacion(
      codigoSeguimiento: 'TX-8F4K2',
      mensaje: 'Recibimos tu postulación. Te escribiremos a tu correo.',
    );
  }
  Future<PostulacionEstado> consultarEstado(String codigo) async {
    await Future.delayed(const Duration(seconds: 1)); 

    final codigoLimpio = codigo.trim().toUpperCase();

    // Usamos el mismo código que generó tu compañera arriba
    if (codigoLimpio == 'TX-8F4K2') {
      return PostulacionEstado(
        codigo: 'TX-8F4K2',
        vacanteTitulo: 'Desarrollador Backend',
        etapaActual: 'Revisión Técnica',
        estado: 'En Progreso',
      );
    } 

    throw Exception('No se encontró ninguna postulación con el código $codigoLimpio.');
  }
}

/// Falla la red: para la captura del estado "con error".
class PostulacionesServiceError extends PostulacionesService {
  PostulacionesServiceError() : super(baseUrl: 'falso');

  @override
  Future<ResultadoPostulacion> postular({
    required String slug,
    required int vacanteId,
    required Postulante postulante,
    required CvAdjunto cv,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    throw PostulacionException(
      503,
      'No se pudo enviar la postulación. '
      'Revisa tu conexión e inténtalo de nuevo.',
    );
  }
}

/// El backend rechaza campos que el cliente sí dio por buenos.
/// Demuestra la regla del equipo: la validación del cliente es solo para UX,
/// la autoridad es el backend.
class PostulacionesServiceValidacion extends PostulacionesService {
  PostulacionesServiceValidacion() : super(baseUrl: 'falso');

  @override
  Future<ResultadoPostulacion> postular({
    required String slug,
    required int vacanteId,
    required Postulante postulante,
    required CvAdjunto cv,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    throw PostulacionException(
      422,
      'Revisa los datos del formulario.',
      erroresPorCampo: const {
        'email': 'Ya existe una postulación con este correo para la vacante.',
        'ci': 'El CI no tiene un formato válido.',
      },
    );
  }
}
