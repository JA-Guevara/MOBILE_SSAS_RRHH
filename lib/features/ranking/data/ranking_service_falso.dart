import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/ranking/data/ranking_service.dart';
import 'package:mobile_ssas_rrhh/features/ranking/model/candidato_ranking.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Servicios FALSOS para desarrollar sin backend, igual que en las otras
/// features. Aquí sirven además para trabajar sin estar autenticado: los
/// fakes no tocan el token.
///
/// Para las 3 capturas de evidencia:
///   con datos  -> RankingServiceFalso
///   vacío      -> RankingServiceVacio
///   con error  -> RankingServiceError
///
/// Cuando el backend esté listo, vuelves a usar RankingService normal.
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Las dependencias reales no se usan en los fakes, pero el constructor de
/// RankingService las pide. Se les pasa una instancia inerte.
AppHttpClient _clienteInerte() => AppHttpClient(baseUrl: 'falso');

/// Cinco candidatos con los nombres y las afinidades de la maqueta de la
/// guía, adrede DESORDENADOS: así se comprueba que la pantalla los ordena.
class RankingServiceFalso extends RankingService {
  RankingServiceFalso() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<CandidatoRanking>> porVacante(int vacanteId) async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 800));

    final lista =
        [
            {
              'id': 11,
              'puntaje_ia': 74,
              'postulante': {
                'nombres': 'Marco',
                'apellidos': 'Terceros',
                'ciudad': 'Santa Cruz',
                'anios_experiencia': 3,
              },
              'etapa': {
                'id': 1,
                'nombre': 'Postulación',
                'orden': 1,
                'es_inicial': true,
                'color': '#3A6EA5',
              },
            },
            {
              'id': 12,
              'puntaje_ia': 87,
              'postulante': {
                'nombres': 'Julia',
                'apellidos': 'Quispe',
                'ciudad': 'Santa Cruz',
                'anios_experiencia': 6,
              },
              'etapa': {
                'id': 1,
                'nombre': 'Postulación',
                'orden': 1,
                'es_inicial': true,
                'color': '#3A6EA5',
              },
            },
            {
              'id': 13,
              'puntaje_ia': 81,
              'postulante': {
                'nombres': 'Renata',
                'apellidos': 'Suárez',
                'ciudad': 'Cochabamba',
                'anios_experiencia': 5,
              },
              'etapa': {
                'id': 2,
                'nombre': 'Preselección',
                'orden': 2,
                'color': '#7A5AA6',
              },
            },
            {
              'id': 14,
              'puntaje_ia': 78,
              'postulante': {
                'nombres': 'Diego',
                'apellidos': 'Roca',
                'ciudad': 'Santa Cruz',
                'anios_experiencia': 4,
              },
              'etapa': {
                'id': 3,
                'nombre': 'Entrevista',
                'orden': 3,
                'color': '#A9731F',
              },
            },
            {
              'id': 15,
              'puntaje_ia': 41,
              'postulante': {
                'nombres': 'Rosa',
                'apellidos': 'Mamani',
                'ciudad': 'La Paz',
                'anios_experiencia': 1,
              },
              'etapa': {
                'id': 1,
                'nombre': 'Postulación',
                'orden': 1,
                'es_inicial': true,
                'color': '#3A6EA5',
              },
            },
            // Un candidato que la IA todavía no puntuó: va al final y su
            // tarjeta sale sin insignia lila, como pide la guía.
            {
              'id': 16,
              'postulante': {
                'nombres': 'Pablo',
                'apellidos': 'Arias',
                'ciudad': 'Santa Cruz',
                'anios_experiencia': 8,
              },
              'etapa': {'id': 4, 'nombre': 'Oferta', 'orden': 4},
            },
          ].map(CandidatoRanking.fromJson).toList()
          ..sort(CandidatoRanking.porAfinidadDesc);

    return lista;
  }
}

/// Devuelve una lista vacía: la vacante todavía no tiene postulantes.
class RankingServiceVacio extends RankingService {
  RankingServiceVacio() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<CandidatoRanking>> porVacante(int vacanteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [];
  }
}

/// Lanza un error de red: para la captura del estado "con error".
class RankingServiceError extends RankingService {
  RankingServiceError() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<CandidatoRanking>> porVacante(int vacanteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException(
      'No se pudo cargar el ranking. '
      'Revisa tu conexión e inténtalo de nuevo.',
      statusCode: 503,
    );
  }
}

/// La sesión caducó: 401. Sirve para demostrar que la pantalla distingue
/// "no hay red" de "no estás autenticado", que es lo nuevo de esta tarea.
class RankingServiceSinSesion extends RankingService {
  RankingServiceSinSesion() : super(_clienteInerte(), MemoryTokenStorage());

  @override
  Future<List<CandidatoRanking>> porVacante(int vacanteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const AppException('No autenticado.', statusCode: 401);
  }
}
