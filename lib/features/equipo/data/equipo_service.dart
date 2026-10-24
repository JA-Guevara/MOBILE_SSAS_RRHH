import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/miembro_equipo.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Equipo a mi cargo (T3-29 · HU-12 · CU-20): las personas que le reportan
/// al jefe autenticado, con su cargo y su asistencia de hoy.
///
/// Pantalla AUTENTICADA, con el mismo mecanismo que T2-20 y T3-18.
/// Es SOLO LECTURA: no hay POST; la gestión del equipo vive en la web.
class EquipoService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  EquipoService(this._client, this._tokenStorage);

  /// No recibe el id del jefe: el backend lo saca del token y filtra los
  /// contratos vigentes por jefe_directo_id. Mandarlo desde el cliente
  /// dejaría ver el equipo de otro jefe.
  Future<List<MiembroEquipo>> miEquipo() async {
    final token = await _tokenStorage.readAccessToken();

    // >>> VERIFICA esta ruta en /docs. <<<  El endpoint todavía no existe:
    // no hay contrato ni asistencia en rrhh-api. Es la propuesta del equipo
    // móvil; en cuanto el backend la publique, se ajusta aquí.
    final respuesta = await _client.get(
      '/empleados/me/equipo',
      accessToken: token,
    );

    final items = respuesta is Map<String, dynamic>
        ? (respuesta['items'] ?? respuesta['data'])
        : respuesta;

    if (items is! List) return const [];

    final lista = items
        .whereType<Map<String, dynamic>>()
        .map(MiembroEquipo.fromJson)
        .toList();

    // Orden alfabético: el jefe busca a una persona por su nombre, y así la
    // lista no baila entre recargas aunque cambien las marcas.
    lista.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
    return lista;
  }
}

/// Traduce el fallo a algo que el jefe entienda, igual que en T2-20. Aquí
/// 401 y 403 se separan: 403 no es "sesión vencida", es que la cuenta no
/// tiene personas a cargo ni permiso para verlas.
String mensajeDeErrorEquipo(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    if (error.statusCode == 403) {
      return 'Esta vista es solo para jefes directos.';
    }
    return error.message;
  }
  return 'No se pudo cargar tu equipo. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
