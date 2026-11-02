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
      _client.get('/personal/tipos-ausencia', accessToken: token),
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
    String? documentoId;
    if (documento != null) {
      final subido = await _client.postMultipart(
        '/personal/mi/documentos',
        campos: {},
        archivos: [
          http.MultipartFile.fromBytes(
            'archivo',
            documento.bytes,
            filename: documento.nombre,
            contentType: MediaType.parse(documento.mimeType),
          ),
        ],
        accessToken: token,
      );
      if (subido is! Map<String, dynamic> || subido['id'] == null) {
        throw const AppException(
          'No se pudo guardar el documento de respaldo.',
        );
      }
      documentoId = subido['id'].toString();
    }
    final cuerpo = <String, Object?>{...solicitud.toFields()};
    if (documentoId != null) cuerpo['documento_id'] = documentoId;
    final respuesta = await _client.post(
      '/personal/mi/ausencias',
      body: cuerpo,
      accessToken: token,
    );

    if (respuesta is! Map<String, dynamic>) {
      throw const AppException('El servidor no devolvió la solicitud creada.');
    }
    final solicitudes = await _client.get(
      '/personal/mi/ausencias',
      accessToken: token,
    );
    final id = respuesta['id']?.toString();
    final detalle = filasDe(solicitudes)
        .where((fila) => fila['id']?.toString() == id)
        .firstOrNull;
    return SolicitudAusencia.fromJson(detalle ?? respuesta)
        .conRelaciones(tipo: solicitud.tipo);
  }
}

/// El saldo de vacaciones del colaborador en su gestión más reciente, o
/// null si no tiene ninguno.
///
/// Es función suelta y no método porque la usan dos pantallas: solicitar
/// permiso (T3-19) y mis días trabajados (T3-21).
Future<SaldoVacacion?> leerSaldoMio(AppHttpClient client, String? token) async {
  final respuesta = await client.get(
    '/personal/mi/vacaciones',
    accessToken: token,
  );
  final saldos = filasDe(respuesta).map(SaldoVacacion.fromJson).toList()
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
