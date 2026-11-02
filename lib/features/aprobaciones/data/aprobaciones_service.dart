import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/shared/api/filas.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/referencias/referencias.dart';

/// Solicitudes que el usuario autenticado tiene permiso de resolver.
class AprobacionesService {
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  AprobacionesService(this._client, this._tokenStorage);

  Future<List<SolicitudAusencia>> pendientes() async {
    final lista = await _consultar();
    return lista.where((s) => s.estaPendiente).toList()
      ..sort(masAntiguaPrimero);
  }

  Future<SolicitudAusencia> detalle(String solicitudId) async {
    final lista = await _consultar();
    for (final solicitud in lista) {
      if (solicitud.id == solicitudId) return solicitud;
    }
    throw const AppException(
      'La solicitud ya no está disponible.',
      statusCode: 404,
    );
  }

  Future<List<SolicitudAusencia>> _consultar() async {
    final token = await _tokenStorage.readAccessToken();
    final respuesta = await _client.get(
      '/personal/mi/equipo/ausencias/resumen',
      accessToken: token,
    );
    return filasDe(respuesta).map((fila) {
      final empleado = fila['empleado'] as Map<String, dynamic>;
      final tipo = fila['tipo'] as Map<String, dynamic>;
      final saldo = fila['saldo'];
      return SolicitudAusencia.fromJson(fila).conRelaciones(
        solicitante: EmpleadoRef.fromJson(empleado).nombreCompleto,
        tipo: TipoAusencia.fromJson(tipo),
        saldo: saldo is Map<String, dynamic>
            ? SaldoVacacion.fromJson(saldo)
            : null,
      );
    }).toList();
  }

  Future<SolicitudAusencia> aprobar(
    String solicitudId, {
    String? observacion,
    int? diasHabilesVacacion,
  }) => _responder(
    solicitudId,
    aprobar: true,
    observacion: observacion,
    diasHabilesVacacion: diasHabilesVacacion,
  );

  Future<SolicitudAusencia> rechazar(
    String solicitudId, {
    required String observacion,
  }) {
    if (observacion.trim().isEmpty) {
      throw const AppException('Explica el motivo del rechazo.');
    }
    return _responder(solicitudId, aprobar: false, observacion: observacion);
  }

  Future<SolicitudAusencia> _responder(
    String solicitudId, {
    required bool aprobar,
    String? observacion,
    int? diasHabilesVacacion,
  }) async {
    final solicitud = await detalle(solicitudId);
    if (aprobar &&
        solicitud.afectaVacaciones &&
        (diasHabilesVacacion == null ||
            diasHabilesVacacion < 1 ||
            diasHabilesVacacion > (solicitud.diasSolicitados ?? 0))) {
      throw const AppException(
        'Indica los días hábiles de vacación verificados.',
      );
    }
    final token = await _tokenStorage.readAccessToken();
    final cuerpo = <String, Object?>{'aprobar': aprobar};
    if (observacion?.trim().isNotEmpty == true) {
      cuerpo['observacion'] = observacion!.trim();
    }
    if (aprobar && solicitud.afectaVacaciones) {
      cuerpo['dias_habiles_vacacion'] = diasHabilesVacacion;
    }
    await _client.post(
      '/personal/ausencias/$solicitudId/decision',
      body: cuerpo,
      accessToken: token,
    );
    return detalle(solicitudId);
  }

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

String mensajeDeErrorAprobaciones(Object error) {
  if (error is AppException) {
    if (error.statusCode == 401) {
      return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    }
    if (error.statusCode == 403) {
      return 'No tienes permiso para resolver esta solicitud.';
    }
    return error.message;
  }
  return 'No se pudo completar la operación. Revisa tu conexión e inténtalo de nuevo.';
}
