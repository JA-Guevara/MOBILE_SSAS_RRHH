import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/model/reglas_tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Configurar los tipos de ausencia desde el móvil (T3-30). Es la versión
/// reducida de la pantalla web: el administrador de la empresa los consulta
/// y edita sus condiciones y su tope anual. Crear y borrar se hace en la
/// web; aquí un tipo se da de baja desactivándolo.
///
/// Pantalla AUTENTICADA: mismo mecanismo que el resto del Sprint 3. No se
/// manda empresa_id: el backend la saca del token del administrador.
class TiposAusenciaService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  TiposAusenciaService(this._client, this._tokenStorage);

  /// Todos los tipos de la empresa, activos primero.
  Future<List<TipoAusencia>> listar() async {
    final token = await _tokenStorage.readAccessToken();
    // Esta ruta YA EXISTE en rrhh-api, pero hoy solo devuelve los activos
    // y cinco columnas. >>> VERIFICA en /docs <<< que, con
    // incluir_inactivos, el administrador reciba también los inactivos (si
    // no, no podría reactivarlos) y las ocho columnas de la tabla.
    final respuesta = await _client.get(
      '/personal/tipos-ausencia?incluir_inactivos=true',
      accessToken: token,
    );
    return filasDe(respuesta).map(TipoAusencia.fromJson).toList()
      ..sort(ReglasTipoAusencia.orden);
  }

  /// Guarda los cambios de un tipo y devuelve cómo quedó en el backend.
  Future<TipoAusencia> guardar(TipoAusencia tipo) async {
    final token = await _tokenStorage.readAccessToken();
    // >>> VERIFICA esta ruta en /docs. <<<  Todavía no existe.
    // Propuesta: PUT con las ocho columnas editables, permiso
    // ausencias:gestionar (el mismo que asignar saldos de vacación).
    final respuesta = await _client.put(
      '/personal/tipos-ausencia/${Uri.encodeComponent(tipo.id)}',
      body: tipo.toJson(),
      accessToken: token,
    );
    // Si el backend no devuelve el registro, lo enviado es lo que quedó.
    return respuesta is Map<String, dynamic>
        ? TipoAusencia.fromJson(respuesta)
        : tipo;
  }
}

/// 401 y 403 se separan: 403 no es "sesión vencida", es que la cuenta no es
/// administradora de la empresa.
String mensajeDeErrorTiposAusencia(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    if (error.statusCode == 403) {
      return 'Esta configuración es solo para el administrador de la '
          'empresa.';
    }
    return error.message;
  }
  return 'No se pudieron cargar los tipos de ausencia. '
      'Revisa tu conexión e inténtalo de nuevo.';
}

/// El fallo al guardar: el detail del backend dice qué estuvo mal (un
/// código repetido, un tope inválido...), así que se muestra tal cual.
String mensajeDeErrorGuardado(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return mensajeDeErrorTiposAusencia(error);
    }
    return error.message;
  }
  return 'No se pudieron guardar los cambios. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
