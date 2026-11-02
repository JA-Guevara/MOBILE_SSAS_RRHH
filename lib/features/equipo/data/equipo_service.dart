import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/contrato.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/miembro_equipo.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/referencias/referencias.dart';

/// Equipo a mi cargo (T3-29 · HU-12 · CU-20): las personas que le reportan
/// al jefe autenticado, con su cargo y su asistencia de hoy.
///
/// Pantalla AUTENTICADA, con el mismo mecanismo que T2-20 y T3-18.
/// Es SOLO LECTURA: no hay POST; la gestión del equipo vive en la web.
class EquipoService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  /// De dónde sale "hoy" para pedir la asistencia del día. Las pruebas lo
  /// fijan; en la app es el reloj del teléfono.
  final DateTime Function() hoy;

  EquipoService(this._client, this._tokenStorage, {this.hoy = DateTime.now});

  /// Pide cada tabla por separado y las une por sus llaves:
  ///   contrato.empleado_id  -> empleado (nombre)
  ///   contrato.cargo_id     -> cargo (nombre)
  ///   asistencia.empleado_id = contrato.empleado_id  (la fila de hoy)
  ///
  /// No se manda el id del jefe: el backend lo saca del token y filtra los
  /// contratos por jefe_directo_id. Mandarlo desde el cliente dejaría ver
  /// el equipo de otro jefe.
  Future<List<MiembroEquipo>> miEquipo() async {
    final token = await _tokenStorage.readAccessToken();

    final r = await Future.wait([
      // >>> VERIFICA estas dos rutas en /docs. <<<  Todavía no existen.
      _client.get('/contratos/mi-equipo', accessToken: token),
      _client.get('/asistencias?fecha=${_fecha(hoy())}', accessToken: token),
      // Estas dos YA EXISTEN en rrhh-api (limit máximo 100).
      _client.get('/empleados?limit=100', accessToken: token),
      _client.get('/cargos', accessToken: token),
    ]);

    final asistencias = <String, Asistencia>{
      for (final a in filasDe(r[1]).map(Asistencia.fromJson))
        if (a.empleadoId != null) a.empleadoId!: a,
    };
    final empleados = porId(filasDe(r[2]), EmpleadoRef.fromJson, (e) => e.id);
    final cargos = porId(filasDe(r[3]), CargoRef.fromJson, (c) => c.id);

    final lista = filasDe(r[0])
        .map(Contrato.fromJson)
        // Contratos versionados: solo cuenta el vigente.
        .where((c) => c.esVigente)
        .map(
          (c) => MiembroEquipo(
            contrato: c,
            empleado: empleados[c.empleadoId],
            cargo: cargos[c.cargoId],
            asistencia: asistencias[c.empleadoId],
          ),
        )
        .toList();

    // Orden alfabético: el jefe busca a una persona por su nombre, y así la
    // lista no baila entre recargas aunque cambien las marcas.
    lista.sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
    return lista;
  }

  /// "2026-10-24", como una columna DATE.
  static String _fecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
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
