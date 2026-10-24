import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/referencias/referencias.dart';

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

  /// Las solicitudes que este jefe tiene por responder, con el nombre del
  /// empleado, su tipo de ausencia y su saldo de vacaciones ya unidos. El
  /// saldo va también en la lista para que la tarjeta avise si no alcanza.
  Future<List<SolicitudAusencia>> pendientes() async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<  El endpoint todavía no existe.
    final r = await Future.wait([
      _client.get('/solicitudes-ausencia/pendientes', accessToken: token),
      _tipos(token),
      _empleados(token),
      _saldos(token),
    ]);
    final tipos = r[1] as Map<String, TipoAusencia>;
    final empleados = r[2] as Map<String, EmpleadoRef>;
    final saldos = r[3] as Map<String, SaldoVacacion>;

    final lista = filasDe(r[0])
        .map(SolicitudAusencia.fromJson)
        .map((s) => _unir(s, tipos, empleados))
        .map(
          (s) => s.afectaVacaciones
              ? s.conRelaciones(saldo: saldos[s.empleadoId])
              : s,
        )
        .toList();

    // La más antigua primero: es la que lleva más tiempo esperando, y en una
    // bandeja de aprobación eso es lo urgente.
    lista.sort(masAntiguaPrimero);

    return lista;
  }

  /// El detalle: la solicitud con su tipo, el nombre del empleado y, si el
  /// tipo descuenta vacación, su saldo. El saldo se pide aquí y no en la
  /// lista porque la bandeja no lo necesita para cada empleado.
  Future<SolicitudAusencia> detalle(String solicitudId) async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<
    final r = await Future.wait([
      _client.get('/solicitudes-ausencia/$solicitudId', accessToken: token),
      _tipos(token),
      _empleados(token),
    ]);

    final fila = r[0];
    if (fila is! Map<String, dynamic>) {
      throw const AppException('El servidor no devolvió la solicitud.');
    }

    final solicitud = _unir(
      SolicitudAusencia.fromJson(fila),
      r[1] as Map<String, TipoAusencia>,
      r[2] as Map<String, EmpleadoRef>,
    );

    if (!solicitud.afectaVacaciones || solicitud.empleadoId == null) {
      return solicitud;
    }
    final saldos = await _saldos(token, empleadoId: solicitud.empleadoId);
    return solicitud.conRelaciones(saldo: saldos[solicitud.empleadoId]);
  }

  /// Aprueba la solicitud. La observación es opcional.
  Future<SolicitudAusencia> aprobar(String solicitudId, {String? observacion}) {
    // >>> VERIFICA esta ruta y esta clave en /docs. <<<
    return _responder(solicitudId, 'aprobar', observacion);
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
    return _responder(solicitudId, 'rechazar', observacion);
  }

  Future<SolicitudAusencia> _responder(
    String solicitudId,
    String accion,
    String? observacion,
  ) async {
    final token = await _tokenStorage.readAccessToken();

    final limpia = observacion?.trim() ?? '';

    await _client.post(
      '/solicitudes-ausencia/$solicitudId/$accion',
      // Solo la columna observacion_aprobador. Si no hay observación no se
      // manda la clave, para que el backend guarde NULL y no "".
      body: {if (limpia.isNotEmpty) 'observacion_aprobador': limpia},
      accessToken: token,
    );

    // Se vuelve a pedir el detalle en vez de leer la respuesta del POST:
    // al aprobar cambia también el saldo de vacaciones, y así la pantalla
    // muestra todo ya actualizado.
    return detalle(solicitudId);
  }

  /// Une la fila con el nombre del empleado y su tipo, por sus llaves.
  static SolicitudAusencia _unir(
    SolicitudAusencia s,
    Map<String, TipoAusencia> tipos,
    Map<String, EmpleadoRef> empleados,
  ) => s.conRelaciones(
    solicitante: empleados[s.empleadoId]?.nombreCompleto,
    tipo: tipos[s.tipoAusenciaId],
  );

  /// Los tipos de ausencia de la empresa, por id.
  Future<Map<String, TipoAusencia>> _tipos(String? token) async {
    // >>> VERIFICA esta ruta en /docs. <<<
    final respuesta = await _client.get('/tipos-ausencia', accessToken: token);
    return porId(filasDe(respuesta), TipoAusencia.fromJson, (t) => t.id);
  }

  /// Los empleados, por id, para mostrar nombres. Este endpoint YA EXISTE
  /// en rrhh-api (limit máximo 100).
  Future<Map<String, EmpleadoRef>> _empleados(String? token) async {
    final respuesta = await _client.get(
      '/empleados?limit=100',
      accessToken: token,
    );
    return porId(filasDe(respuesta), EmpleadoRef.fromJson, (e) => e.id);
  }

  /// El saldo de vacaciones de cada empleado en su gestión más reciente,
  /// por empleado_id. Con [empleadoId] se pide solo el de esa persona.
  Future<Map<String, SaldoVacacion>> _saldos(
    String? token, {
    String? empleadoId,
  }) async {
    final filtro = empleadoId == null
        ? ''
        : '?empleado_id=${Uri.encodeQueryComponent(empleadoId)}';
    // >>> VERIFICA esta ruta en /docs. <<<
    final respuesta = await _client.get(
      '/saldos-vacacion$filtro',
      accessToken: token,
    );

    // De la gestión más antigua a la más reciente: al armar el mapa, la
    // más reciente de cada empleado pisa a las anteriores.
    final saldos = filasDe(respuesta).map(SaldoVacacion.fromJson).toList()
      ..sort((a, b) => (a.gestion ?? 0).compareTo(b.gestion ?? 0));
    return {
      for (final s in saldos)
        if (s.empleadoId != null) s.empleadoId!: s,
    };
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
