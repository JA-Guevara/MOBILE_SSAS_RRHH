import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/nueva_solicitud.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/opciones_solicitud.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Solicitar permiso o vacaciones desde el móvil (T3-19 · HU-16 · CU-24).
///
/// Pantalla AUTENTICADA: mismo mecanismo que T3-18, T3-20 y T3-22 —
/// `AppHttpClient` pone el header `Authorization: Bearer <token>` y
/// `TokenStorage` dice de dónde sale.
///
/// No se manda empleado_id en ninguna llamada: el backend lo saca del token,
/// igual que en /boletas. Si lo mandara el cliente, cualquiera podría ver el
/// saldo de otro o pedir vacaciones a su nombre.
class SolicitudesService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  SolicitudesService(this._client, this._tokenStorage);

  /// Los tipos de ausencia activos de la empresa y el saldo de vacaciones
  /// del colaborador, pedidos a la vez.
  Future<OpcionesSolicitud> opciones() async {
    final token = await _tokenStorage.readAccessToken();

    final r = await Future.wait([
      // Misma ruta que usa la bandeja del jefe (T3-22).
      // >>> VERIFICA esta ruta en /docs. <<<  Todavía no existe (T3-06).
      _client.get('/tipos-ausencia', accessToken: token),
      leerSaldoMio(_client, token),
    ]);

    final tipos = filasDe(r[0])
        .map(TipoAusencia.fromJson)
        .where((t) => t.activo)
        .toList();

    return OpcionesSolicitud(tipos: tipos, saldo: r[1] as SaldoVacacion?);
  }

  /// Registra la solicitud y devuelve la fila creada (estado pendiente).
  ///
  /// Va como multipart, igual que la postulación de T1-20, porque puede
  /// llevar el documento de respaldo. Sin documento se manda igual: así el
  /// backend tiene un solo formato que leer.
  Future<SolicitudAusencia> enviar(NuevaSolicitud solicitud) async {
    final token = await _tokenStorage.readAccessToken();
    final documento = solicitud.documento;

    // >>> VERIFICA esta ruta y el nombre de la parte ("documento") en
    // /docs. <<<  Todavía no existe (T3-06).
    final respuesta = await _client.postMultipart(
      '/solicitudes-ausencia',
      campos: solicitud.toFields(),
      archivos: [
        if (documento != null)
          http.MultipartFile.fromBytes(
            'documento',
            documento.bytes,
            filename: documento.nombre,
            contentType: MediaType.parse(documento.mimeType),
          ),
      ],
      accessToken: token,
    );

    if (respuesta is! Map<String, dynamic>) {
      throw const AppException('El servidor no devolvió la solicitud creada.');
    }
    return SolicitudAusencia.fromJson(respuesta)
        .conRelaciones(tipo: solicitud.tipo);
  }
}

/// El saldo de vacaciones del colaborador en su gestión más reciente, o
/// null si no tiene ninguno.
///
/// Es función suelta y no método porque la usan dos pantallas: solicitar
/// permiso (T3-19) y mis días trabajados (T3-21).
Future<SaldoVacacion?> leerSaldoMio(AppHttpClient client, String? token) async {
  final Object? respuesta;
  try {
    // >>> VERIFICA esta ruta en /docs. <<<  Propuesta del móvil: hoy
    // ningún endpoint dice qué empleado es el usuario (hallazgo H-2 de
    // T3-23), así que el backend tiene que resolverlo con el token.
    respuesta = await client.get('/saldos-vacacion/mio', accessToken: token);
  } on AppException catch (e) {
    // Sin saldo asignado no es un error: la pantalla lo dice y sigue.
    if (e.statusCode == 404) return null;
    rethrow;
  }

  // Puede venir una sola fila o la lista de todas sus gestiones.
  final filas =
      respuesta is Map<String, dynamic> &&
          !respuesta.containsKey('items') &&
          !respuesta.containsKey('data')
      ? [respuesta]
      : filasDe(respuesta);

  final saldos = filas.map(SaldoVacacion.fromJson).toList()
    ..sort((a, b) => (a.gestion ?? 0).compareTo(b.gestion ?? 0));
  return saldos.isEmpty ? null : saldos.last;
}

/// Traduce el fallo al cargar a algo que el colaborador entienda, igual que
/// en las otras pantallas autenticadas.
String mensajeDeErrorSolicitudes(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión para solicitar '
          'permisos o vacaciones.';
    }
    return error.message;
  }
  return 'No se pudieron cargar los tipos de ausencia. '
      'Revisa tu conexión e inténtalo de nuevo.';
}

/// Traduce el fallo al enviar. Un 422 o un 409 traen el motivo del backend
/// (saldo insuficiente, fechas que se cruzan con otra solicitud...), que es
/// más útil que cualquier texto genérico.
String mensajeDeErrorEnvio(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión y envía la '
          'solicitud otra vez.';
    }
    return error.message;
  }
  return 'No se pudo enviar la solicitud. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
