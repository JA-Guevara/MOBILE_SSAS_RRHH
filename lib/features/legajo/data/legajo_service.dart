import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/legajo/model/documento_empleado.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Mi legajo digital (T3-27 · HU-12 · CU-20): los documentos personales del
/// colaborador autenticado.
///
/// Pantalla AUTENTICADA, con el mismo mecanismo que T2-20 y T3-18:
/// `AppHttpClient` pone el header `Authorization: Bearer <token>` y
/// `TokenStorage` dice de dónde sale.
class LegajoService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  LegajoService(this._client, this._tokenStorage);

  /// Documentos del colaborador autenticado. No recibe empleado_id: el
  /// backend lo saca del token, igual que en la marcación de asistencia.
  Future<List<DocumentoEmpleado>> mios() async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<  El endpoint todavía no existe:
    // T3-02 solo cubre el legajo que ve RR. HH. desde la web. Es la
    // propuesta del equipo móvil para el autoservicio del colaborador.
    final respuesta = await _client.get(
      '/documentos-empleado/mios',
      accessToken: token,
    );

    return filasDe(respuesta).map(DocumentoEmpleado.fromJson).toList();
  }
}

/// Traduce el fallo a algo que el colaborador entienda, igual que en T2-20.
String mensajeDeErrorLegajo(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión para ver tus '
          'documentos.';
    }
    return error.message;
  }
  return 'No se pudieron cargar tus documentos. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
