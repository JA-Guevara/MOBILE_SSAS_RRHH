import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Bandeja de aprobación del jefe (T3-22 · HU-17 · CU-25).
///
/// Pantalla AUTENTICADA: mismo mecanismo que T2-20, T3-18 y T3-20 —
/// `AppHttpClient` pone el header `Authorization: Bearer <token>` y
/// `TokenStorage` dice de dónde sale.
///
/// No se manda aprobador_id en ninguna llamada: el backend lo saca del
/// token. Si lo pusiera el cliente, cualquiera podría aprobar en nombre de
/// otro jefe, que en esta pantalla es lo más grave que podría pasar.
class AprobacionesService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  AprobacionesService(this._client, this._tokenStorage);

  /// Las solicitudes que este jefe tiene por responder.
  Future<List<SolicitudAusencia>> pendientes() async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<  El endpoint todavía no existe.
    final respuesta = await _client.get(
      '/solicitudes-ausencia/pendientes',
      accessToken: token,
    );

    final items = respuesta is Map<String, dynamic>
        ? (respuesta['items'] ?? respuesta['data'])
        : respuesta;

    if (items is! List) return const [];

    final lista = items
        .whereType<Map<String, dynamic>>()
        .map(SolicitudAusencia.fromJson)
        .toList();

    // La más antigua primero: es la que lleva más tiempo esperando, y en una
    // bandeja de aprobación eso es lo urgente.
    lista.sort(masAntiguaPrimero);

    return lista;
  }

  /// El detalle, que trae el tipo de ausencia y el saldo de vacaciones.
  /// Se pide aparte porque la lista no necesita el saldo de cada empleado.
  Future<SolicitudAusencia> detalle(String solicitudId) async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<
    final respuesta = await _client.get(
      '/solicitudes-ausencia/$solicitudId',
      accessToken: token,
    );

    if (respuesta is! Map<String, dynamic>) {
      throw const AppException('El servidor no devolvió la solicitud.');
    }

    return SolicitudAusencia.fromJson(respuesta);
  }

  /// Aprueba la solicitud. La observación es opcional.
  Future<SolicitudAusencia> aprobar(String solicitudId, {String? observacion}) {
    // >>> VERIFICA esta ruta y esta clave en /docs. <<<
    return _responder(
      '/solicitudes-ausencia/$solicitudId/aprobar',
      observacion,
    );
  }

  /// Rechaza la solicitud. La observación es OBLIGATORIA: un rechazo sin
  /// motivo deja al empleado sin saber qué corregir. La pantalla ya no deja
  /// llegar aquí sin ella; esta comprobación es la última red.
  Future<SolicitudAusencia> rechazar(
    String solicitudId, {
    required String observacion,
  }) {
    if (observacion.trim().isEmpty) {
      throw const AppException(
        'Para rechazar una solicitud hay que explicar el motivo.',
      );
    }
    // >>> VERIFICA esta ruta y esta clave en /docs. <<<
    return _responder(
      '/solicitudes-ausencia/$solicitudId/rechazar',
      observacion,
    );
  }

  Future<SolicitudAusencia> _responder(String ruta, String? observacion) async {
    final token = await _tokenStorage.readAccessToken();

    final limpia = observacion?.trim() ?? '';

    final respuesta = await _client.post(
      ruta,
      // Si no hay observación no se manda la clave, para que el backend
      // guarde NULL y no una cadena vacía.
      body: {if (limpia.isNotEmpty) 'observacion_aprobador': limpia},
      accessToken: token,
    );

    if (respuesta is! Map<String, dynamic>) {
      throw const AppException('El servidor no devolvió la solicitud.');
    }

    return SolicitudAusencia.fromJson(respuesta);
  }

  /// Ordena por fecha de solicitud, la más antigua primero. Las que no traen
  /// fecha van al final, para no colarse arriba por falta de datos.
  static int masAntiguaPrimero(SolicitudAusencia a, SolicitudAusencia b) {
    final fa = a.fechaSolicitud;
    final fb = b.fechaSolicitud;
    if (fa == null && fb == null) return a.id.compareTo(b.id);
    if (fa == null) return 1;
    if (fb == null) return -1;
    final cmp = fa.compareTo(fb);
    return cmp != 0 ? cmp : a.id.compareTo(b.id);
  }
}

/// Traduce el fallo a algo que el jefe entienda, igual que en las otras
/// pantallas autenticadas.
String mensajeDeErrorAprobaciones(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró o no tienes permiso para aprobar. '
          'Vuelve a iniciar sesión.';
    }
    // 409: otro aprobador respondió antes desde la web. Su mensaje es más
    // útil que uno genérico.
    if (error.statusCode == 409) return error.message;
    return error.message;
  }
  return 'No se pudo completar la operación. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
