import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/contrato.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/model/historial_contratos.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/referencias/referencias.dart';

/// Mi contrato vigente y sus versiones anteriores (T3-28 · HU-11 · CU-21).
/// Solo lectura: esta pantalla no modifica nada.
///
/// Pantalla AUTENTICADA: mismo mecanismo que el resto del Sprint 3 —
/// `AppHttpClient` pone el header `Authorization: Bearer <token>` y
/// `TokenStorage` dice de dónde sale.
///
/// No se manda empleado_id: el backend lo saca del token. Si lo mandara el
/// cliente, cualquiera podría ver el salario de otro.
class MiContratoService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  MiContratoService(this._client, this._tokenStorage);

  /// Todas las versiones del contrato del colaborador, con el nombre del
  /// cargo de cada una.
  Future<HistorialContratos> historial() async {
    final token = await _tokenStorage.readAccessToken();

    final r = await Future.wait([
      // >>> VERIFICA esta ruta en /docs. <<<  Todavía no existe (T3-03).
      // Propuesta: todas las filas de "contrato" del usuario, la vigente
      // y las anteriores.
      _client.get('/contratos/mios', accessToken: token),
      // Esta YA EXISTE en rrhh-api.
      _client.get('/cargos', accessToken: token),
    ]);

    return HistorialContratos.desde(
      filasDe(r[0]).map(Contrato.fromJson),
      porId(filasDe(r[1]), CargoRef.fromJson, (c) => c.id),
    );
  }
}

/// Traduce el fallo a algo que el colaborador entienda, igual que en las
/// otras pantallas autenticadas.
String mensajeDeErrorMiContrato(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión para ver tu '
          'contrato.';
    }
    return error.message;
  }
  return 'No se pudo cargar tu contrato. '
      'Revisa tu conexión e inténtalo de nuevo.';
}
