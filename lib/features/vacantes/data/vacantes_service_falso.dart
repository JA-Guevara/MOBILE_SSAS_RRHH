import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service.dart';

/// Servicios FALSOS para desarrollar sin backend.
///
/// Sirven para dos cosas:
///   1. Construir y ver la pantalla mientras el endpoint real no existe.
///   2. Sacar las 3 capturas de evidencia (con datos / vacía / error).
///
/// Cuando el backend esté listo, vuelves a usar VacantesService normal.
/// No borres este archivo: también sirve para pruebas automatizadas.
///
/// Ubicación sugerida:  lib/features/vacantes/data/vacantes_service_falso.dart

/// Devuelve dos vacantes de ejemplo. Usa los MISMOS nombres de campo
/// del diagrama de clases, para que al cambiar al backend real no falle nada.
class VacantesServiceFalso extends VacantesService {
  VacantesServiceFalso() : super(baseUrl: 'falso');

  @override
  Future<List<Vacante>> vacantesPublicas(String slug) async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      Vacante.fromJson({
        'id': 1,
        'titulo': 'Desarrollador Backend',
        'modalidad': 'Híbrido',
        'ubicacion': 'Santa Cruz',
        'fecha_cierre': '2026-09-10',
        'descripcion': 'Buscamos un Desarrollador Backend proactivo para unirse a nuestro equipo. Serás responsable de diseñar, construir y mantener APIs robustas usando Python y Django.',
        'requisitos': [
          'Experiencia comprobable de 2+ años en desarrollo Backend.',
          'Dominio de Python y framework Django.',
          'Conocimiento en bases de datos PostgreSQL y Git.'
        ],
        'beneficios': [
          'Seguro de salud privado.',
          'Horarios flexibles.'
        ],
        'salario': null, // Probando la condición de ClickUp: no se mostrará
      }),
      Vacante.fromJson({
        'id': 2,
        'titulo': 'Auxiliar Contable',
        'modalidad': 'Presencial',
        'ubicacion': 'Santa Cruz',
        'fecha_cierre': '2026-09-15',
        'descripcion': 'Buscamos Auxiliar Contable con atención al detalle para el área de finanzas.',
        'requisitos': [
          'Estudiante de últimos semestres o egresado de Contaduría Pública.',
          'Manejo de Excel intermedio/avanzado.'
        ],
        'beneficios': [
          'Capacitación constante.',
          'Buen clima laboral.'
        ],
        'salario': 3500.00, // Este sí se mostrará en la UI
      }),
    ];
  }

  // MÉTODO NUEVO PARA T1-19: Obtiene el detalle simulado usando el ID
  Future<Vacante> obtenerDetalle(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lista = await vacantesPublicas('falso');
    return lista.firstWhere((v) => v.id == id, orElse: () => throw Exception('Vacante no encontrada'));
  }
}
/// Devuelve una lista vacía: para la captura del estado "sin vacantes".
class VacantesServiceVacio extends VacantesService {
  VacantesServiceVacio() : super(baseUrl: 'falso');

  @override
  Future<List<Vacante>> vacantesPublicas(String slug) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}

/// Lanza un error: para la captura del estado "con error".
class VacantesServiceError extends VacantesService {
  VacantesServiceError() : super(baseUrl: 'falso');

  @override
  Future<List<Vacante>> vacantesPublicas(String slug) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw ApiException(
      500,
      'No se pudieron cargar las vacantes. '
      'Revisa tu conexión e inténtalo de nuevo.',
    );
  }
}
