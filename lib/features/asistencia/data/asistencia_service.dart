import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Marcación de asistencia del colaborador (T3-18 · HU-15 · CU-23).
///
/// Pantalla AUTENTICADA: usa el mismo mecanismo que BitacoraApi y que el
/// ranking de T2-20 — `AppHttpClient` pone el header
/// `Authorization: Bearer <token>` y `TokenStorage` dice de dónde sale.
/// No se lee el almacenamiento seguro por nuestra cuenta.
///
/// Sigue en pie el problema de T2-20: hoy AppProviders arma esto con
/// MemoryTokenStorage y login_screen.dart guarda su token en otro sitio.
/// Ver la lista de supuestos.
class AsistenciaService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  AsistenciaService(this._client, this._tokenStorage);

  /// La marca de hoy del colaborador autenticado. Devuelve null si todavía
  /// no marcó nada: ese null es el estado "sin marcar" de la pantalla.
  ///
  /// No recibe empleado_id: el backend lo saca del token. Mandarlo desde el
  /// cliente dejaría marcar por otro.
  Future<Asistencia?> deHoy() async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<  El endpoint todavía no existe.
    final respuesta = await _client.get('/asistencias/hoy', accessToken: token);

    if (respuesta == null) return null;
    if (respuesta is! Map<String, dynamic>) return null;

    // Un cuerpo vacío o {"asistencia": null} también significa "sin marcar".
    final cuerpo = respuesta['data'] ?? respuesta['asistencia'] ?? respuesta;
    if (cuerpo is! Map<String, dynamic> || cuerpo.isEmpty) return null;

    return Asistencia.fromJson(cuerpo);
  }

  /// Registra la hora de entrada con las coordenadas donde se marcó.
  Future<Asistencia> marcarEntrada({
    required double latitud,
    required double longitud,
  }) {
    // >>> VERIFICA esta ruta y estas claves en /docs. <<<
    return _marcar('/asistencias/entrada', {
      'latitud_entrada': latitud,
      'longitud_entrada': longitud,
      'origen': Asistencia.origenMovil,
    });
  }

  /// Registra la hora de salida con las coordenadas donde se marcó.
  Future<Asistencia> marcarSalida({
    required double latitud,
    required double longitud,
  }) {
    // >>> VERIFICA esta ruta y estas claves en /docs. <<<
    return _marcar('/asistencias/salida', {
      'latitud_salida': latitud,
      'longitud_salida': longitud,
    });
  }

  Future<Asistencia> _marcar(String ruta, Map<String, Object?> cuerpo) async {
    final token = await _tokenStorage.readAccessToken();

    final respuesta = await _client.post(
      ruta,
      body: cuerpo,
      accessToken: token,
    );

    if (respuesta is! Map<String, dynamic>) {
      throw const AppException('El servidor no devolvió la marca registrada.');
    }

    return Asistencia.fromJson(respuesta);
  }
}

/// Traduce el fallo a algo que el colaborador entienda, igual que en T2-20.
String mensajeDeErrorAsistencia(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión para marcar.';
    }
    // El backend impone "una marca por día": si ya está marcado, responde
    // con un conflicto y su mensaje es más útil que uno genérico.
    if (error.statusCode == 409) return error.message;
    return error.message;
  }
  return 'No se pudo registrar tu marca. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
