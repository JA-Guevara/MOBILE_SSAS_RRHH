import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/model/mes_trabajado.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Mis días trabajados y saldo de vacaciones (T3-21 · HU-15).
///
/// Pantalla AUTENTICADA: mismo mecanismo que T3-18 y T3-19 —
/// `AppHttpClient` pone el header `Authorization: Bearer <token>` y
/// `TokenStorage` dice de dónde sale.
///
/// No se manda empleado_id: el backend lo saca del token, igual que en
/// /asistencias/hoy (T3-18). Si lo mandara el cliente, cualquiera podría ver
/// las marcas de otro.
class MisDiasService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  MisDiasService(this._client, this._tokenStorage);

  /// Las marcas del mes de [mes] y el saldo de vacaciones, pedidos a la vez.
  Future<MesTrabajado> delMes(DateTime mes) async {
    final token = await _tokenStorage.readAccessToken();
    final primero = DateTime(mes.year, mes.month);

    final r = await Future.wait([
      // >>> VERIFICA esta ruta en /docs. <<<  Todavía no existe (T3-05).
      // Propuesta: las filas de "asistencia" del usuario en ese mes.
      _client.get(
        '/asistencias/mias?mes=${MesTrabajado.parametroMes(primero)}',
        accessToken: token,
      ),
      leerSaldoMio(_client, token),
    ]);

    final dias =
        filasDe(r[0])
            .map(Asistencia.fromJson)
            // Si el backend ignorara el filtro, el mes no se mezcla con otros.
            .where(
              (d) =>
                  d.fecha != null &&
                  d.fecha!.year == primero.year &&
                  d.fecha!.month == primero.month,
            )
            .toList()
          // El día más reciente arriba: es el que el colaborador busca.
          ..sort((a, b) => b.fecha!.compareTo(a.fecha!));

    return MesTrabajado(
      mes: primero,
      dias: dias,
      saldo: r[1] as SaldoVacacion?,
    );
  }
}

/// Traduce el fallo a algo que el colaborador entienda, igual que en las
/// otras pantallas autenticadas.
String mensajeDeErrorMisDias(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión para ver tus días '
          'trabajados.';
    }
    return error.message;
  }
  return 'No se pudieron cargar tus días trabajados. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
