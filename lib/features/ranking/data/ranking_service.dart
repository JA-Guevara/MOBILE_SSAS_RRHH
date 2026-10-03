import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/ranking/model/candidato_ranking.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Ranking de candidatos de una vacante (T2-20 · HU-07 · CU-14).
///
/// A DIFERENCIA de T1-18, T1-20 y T2-18, esta pantalla NO es pública:
/// la consulta un reclutador autenticado. Por eso no usa el cliente http
/// suelto de las otras features, sino el mismo mecanismo que ya usa
/// BitacoraApi, la única feature autenticada que existe hoy en el repo:
///
///   AppHttpClient  ->  pone el header `Authorization: Bearer <token>`
///   TokenStorage   ->  de dónde sale ese token
///
/// Se inyectan los dos, igual que BitacoraApi, para no crear un mecanismo
/// nuevo ni leer el almacenamiento seguro por nuestra cuenta.
///
/// OJO: hoy AppProviders arma esto con MemoryTokenStorage, que se vacía al
/// cerrar la app, y login_screen.dart guarda su token en otro sitio.
/// Ver la lista de supuestos de la tarea.
class RankingService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  RankingService(this._client, this._tokenStorage);

  /// Candidatos de la vacante, de mayor a menor afinidad.
  Future<List<CandidatoRanking>> porVacante(int vacanteId) async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<  El endpoint todavía no existe.
    // La guía menciona GET /vacantes/{id}/tablero para el kanban de la web;
    // si el equipo prefiere reusarlo, aquí habría que aplanar sus columnas.
    final respuesta = await _client.get(
      '/vacantes/$vacanteId/ranking',
      accessToken: token,
    );

    // El backend puede devolver una lista directa o envolverla en
    // {"items": [...]} / {"data": [...]}, igual que en las otras features.
    final items = respuesta is Map<String, dynamic>
        ? (respuesta['items'] ?? respuesta['data'])
        : respuesta;

    if (items is! List) return const [];

    final lista = items
        .whereType<Map<String, dynamic>>()
        .map(CandidatoRanking.fromJson)
        .toList();

    // El orden lo debería dar el backend, pero se reordena aquí para que la
    // pantalla cumpla su promesa aunque llegue desordenado.
    lista.sort(CandidatoRanking.porAfinidadDesc);

    return lista;
  }
}

/// Traduce el fallo a algo que el reclutador entienda. Se separa de la
/// pantalla para que el texto no viva dentro de un widget.
String mensajeDeError(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró o no tienes permiso para ver este ranking. '
          'Vuelve a iniciar sesión.';
    }
    return error.message;
  }
  return 'No se pudo cargar el ranking. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
