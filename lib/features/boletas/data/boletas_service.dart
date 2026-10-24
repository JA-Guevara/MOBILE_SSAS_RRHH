import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_pago.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Boletas de pago del colaborador (T3-20 · HU-14 · CU-27).
///
/// Pantalla AUTENTICADA: mismo mecanismo que el ranking de T2-20 y la
/// asistencia de T3-18 — `AppHttpClient` pone el header
/// `Authorization: Bearer <token>` y `TokenStorage` dice de dónde sale.
///
/// No se manda empleado_id en ninguna llamada: el backend lo saca del token.
/// Si lo mandara el cliente, cualquiera podría pedir la boleta de otro.
class BoletasService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  BoletasService(this._client, this._tokenStorage);

  /// Las boletas del colaborador, de la más reciente a la más antigua.
  Future<List<BoletaPago>> mias() async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<  El endpoint todavía no existe.
    final respuesta = await _client.get('/boletas', accessToken: token);

    final items = respuesta is Map<String, dynamic>
        ? (respuesta['items'] ?? respuesta['data'])
        : respuesta;

    if (items is! List) return const [];

    final lista = items
        .whereType<Map<String, dynamic>>()
        .map(BoletaPago.fromJson)
        .toList();

    // El backend debería devolverlas ordenadas, pero se reordena aquí para
    // que la pantalla cumpla su promesa aunque lleguen desordenadas.
    lista.sort(masRecientePrimero);

    return lista;
  }

  /// La boleta con sus líneas de haberes y descuentos.
  ///
  /// Se pide aparte porque el listado no necesita las líneas: traerlas para
  /// todas las boletas sería pedir mucho para mostrar poco.
  Future<BoletaPago> detalle(String boletaId) async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<
    final respuesta = await _client.get(
      '/boletas/$boletaId',
      accessToken: token,
    );

    if (respuesta is! Map<String, dynamic>) {
      throw const AppException('El servidor no devolvió la boleta.');
    }

    return BoletaPago.fromJson(respuesta);
  }

  /// Ordena por periodo: primero gestión, luego mes. Las boletas sin periodo
  /// resuelto van al final, para no colarse arriba por falta de datos.
  static int masRecientePrimero(BoletaPago a, BoletaPago b) {
    final pa = a.periodo;
    final pb = b.periodo;
    if (pa == null && pb == null) return b.id.compareTo(a.id);
    if (pa == null) return 1;
    if (pb == null) return -1;

    final gestion = (pb.gestion ?? 0).compareTo(pa.gestion ?? 0);
    if (gestion != 0) return gestion;

    final mes = (pb.mes ?? 0).compareTo(pa.mes ?? 0);
    if (mes != 0) return mes;

    return b.id.compareTo(a.id);
  }
}

/// Traduce el fallo a algo que el colaborador entienda, igual que en T2-20
/// y T3-18.
String mensajeDeErrorBoletas(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión para ver tus boletas.';
    }
    return error.message;
  }
  return 'No se pudieron cargar tus boletas. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
