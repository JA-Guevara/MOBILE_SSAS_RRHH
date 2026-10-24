import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// En qué punto está la solicitud.
///
/// >>> VERIFICA contra /docs <<<  Los literales de solicitud_ausencia.estado
/// son una suposición. Lo que no se reconozca cae en [otro] y se muestra tal
/// cual, sin fingir que está pendiente.
enum EstadoSolicitud { pendiente, aprobada, rechazada, cancelada, otro }

/// Una solicitud de ausencia esperando respuesta del jefe (T3-22 · HU-17 · CU-25).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Campos de la tabla "solicitud_ausencia" del diagrama:
///   id, empresa_id, empleado_id, tipo_ausencia_id, aprobador_id,
///   fecha_inicio, fecha_fin, dias_solicitados, motivo, documento_url,
///   estado, observacion_aprobador, fecha_solicitud, fecha_respuesta
class SolicitudAusencia {
  final String id;
  final String? empresaId;
  final String? empleadoId;
  final String? tipoAusenciaId;
  final String? aprobadorId;

  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double? diasSolicitados;
  final String? motivo;
  final String? documentoUrl;

  final EstadoSolicitud estado;

  /// Lo que mandó el backend en "estado", tal cual, para poder depurar.
  final String? estadoCrudo;

  final String? observacionAprobador;
  final DateTime? fechaSolicitud;
  final DateTime? fechaRespuesta;

  /// >>> VERIFICA contra /docs <<<  La tabla guarda empleado_id, pero el jefe
  /// necesita ver un nombre, no un identificador.
  final String solicitante;

  /// >>> VERIFICA contra /docs <<<  Cargo del solicitante, para dar contexto.
  final String? cargoSolicitante;

  /// >>> VERIFICA contra /docs <<<  La tabla guarda tipo_ausencia_id; aquí se
  /// espera el tipo ya resuelto, porque de él depende si se pide documento y
  /// si se enseña el saldo de vacaciones.
  final TipoAusencia? tipo;

  /// Saldo de vacaciones del solicitante. Solo tiene sentido cuando el tipo
  /// descuenta vacación. Viene en el detalle, no en la lista.
  final SaldoVacacion? saldo;

  const SolicitudAusencia({
    required this.id,
    required this.solicitante,
    required this.estado,
    this.empresaId,
    this.empleadoId,
    this.tipoAusenciaId,
    this.aprobadorId,
    this.fechaInicio,
    this.fechaFin,
    this.diasSolicitados,
    this.motivo,
    this.documentoUrl,
    this.estadoCrudo,
    this.observacionAprobador,
    this.fechaSolicitud,
    this.fechaRespuesta,
    this.cargoSolicitante,
    this.tipo,
    this.saldo,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory SolicitudAusencia.fromJson(Map<String, dynamic> json) {
    // El backend puede devolver el objeto directo o envuelto, igual que en
    // las otras features.
    final cuerpo =
        (json['data'] ?? json['solicitud'] ?? json) as Map<String, dynamic>;

    final tipoJson = cuerpo['tipo_ausencia'] ?? cuerpo['tipo'];
    final saldoJson = cuerpo['saldo_vacacion'] ?? cuerpo['saldo'];
    final crudo = cuerpo['estado']?.toString();

    return SolicitudAusencia(
      id: leerId(cuerpo['id']) ?? '',
      empresaId: leerId(cuerpo['empresa_id']),
      empleadoId: leerId(cuerpo['empleado_id']),
      tipoAusenciaId: leerId(cuerpo['tipo_ausencia_id']),
      aprobadorId: leerId(cuerpo['aprobador_id']),
      fechaInicio: _parseFecha(cuerpo['fecha_inicio']),
      fechaFin: _parseFecha(cuerpo['fecha_fin']),
      diasSolicitados: (cuerpo['dias_solicitados'] as num?)?.toDouble(),
      motivo: _texto(cuerpo['motivo']),
      documentoUrl: _texto(cuerpo['documento_url']),
      estado: parseEstado(crudo),
      estadoCrudo: crudo,
      observacionAprobador: _texto(cuerpo['observacion_aprobador']),
      fechaSolicitud: _parseFecha(cuerpo['fecha_solicitud']),
      fechaRespuesta: _parseFecha(cuerpo['fecha_respuesta']),
      solicitante: _solicitante(cuerpo),
      cargoSolicitante: _anidado(cuerpo, 'empleado', 'cargo', 'cargo'),
      tipo: tipoJson is Map<String, dynamic>
          ? TipoAusencia.fromJson(tipoJson)
          : null,
      saldo: saldoJson is Map<String, dynamic>
          ? SaldoVacacion.fromJson(saldoJson)
          : null,
    );
  }

  /// >>> VERIFICA contra /docs <<<  Se aceptan las familias más probables
  /// en español; lo que no encaje cae en [EstadoSolicitud.otro].
  static EstadoSolicitud parseEstado(String? valor) {
    final v = (valor ?? '').trim().toLowerCase();
    if (v.startsWith('pend')) return EstadoSolicitud.pendiente;
    if (v.startsWith('aprob')) return EstadoSolicitud.aprobada;
    if (v.startsWith('rechaz')) return EstadoSolicitud.rechazada;
    if (v.startsWith('cancel') || v.startsWith('anul')) {
      return EstadoSolicitud.cancelada;
    }
    return EstadoSolicitud.otro;
  }

  /// El nombre puede venir plano ("solicitante", "empleado_nombre") o
  /// anidado en "empleado": {"nombres": ..., "apellidos": ...}.
  static String _solicitante(Map<String, dynamic> cuerpo) {
    for (final clave in ['solicitante', 'empleado_nombre']) {
      final directo = _texto(cuerpo[clave]);
      if (directo != null) return directo;
    }

    final sub = cuerpo['empleado'];
    if (sub is Map) {
      final partes = [
        _texto(sub['nombres']) ?? '',
        _texto(sub['apellidos']) ?? '',
      ].where((s) => s.isNotEmpty);
      if (partes.isNotEmpty) return partes.join(' ');

      final nombre = _texto(sub['nombre']);
      if (nombre != null) return nombre;
    }

    return '';
  }

  static String? _anidado(
    Map<String, dynamic> cuerpo,
    String objeto,
    String campo,
    String plano,
  ) {
    final directo = _texto(cuerpo[plano]);
    if (directo != null) return directo;

    final sub = cuerpo[objeto];
    if (sub is Map) return _texto(sub[campo]);
    return null;
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Un texto vacío del backend significa "no hay dato", no cadena vacía.
  static String? _texto(dynamic valor) {
    if (valor == null) return null;
    final s = valor.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ------------------------------------------------------------- para mostrar

  bool get estaPendiente => estado == EstadoSolicitud.pendiente;

  /// Solo se puede responder lo que sigue pendiente. Si otro jefe ya
  /// respondió desde la web, los botones tienen que desaparecer.
  bool get sePuedeResponder => estaPendiente;

  /// True cuando el tipo descuenta vacación: es cuando el jefe necesita ver
  /// el saldo para decidir informado.
  bool get afectaVacaciones => tipo?.descuentaVacacion ?? false;

  /// True si el tipo exige documento y la solicitud no lo trae. El jefe
  /// tiene que verlo antes de aprobar.
  bool get faltaDocumento =>
      (tipo?.requiereDocumento ?? false) && documentoUrl == null;

  /// "12/09 al 16/09". Devuelve "" si faltan las fechas.
  String get rangoFechas {
    final inicio = _corta(fechaInicio);
    final fin = _corta(fechaFin);
    if (inicio.isEmpty && fin.isEmpty) return '';
    if (fin.isEmpty || inicio == fin) return inicio;
    return '$inicio al $fin';
  }

  /// "5 días" o "1 día". Devuelve "" si el backend no mandó la cantidad.
  String get diasTexto {
    final d = diasSolicitados;
    if (d == null) return '';
    final texto = SaldoVacacion.dias(d);
    return d == 1 ? '$texto día' : '$texto días';
  }

  /// "12/09 al 16/09 · 5 días", la línea de la tarjeta.
  String get subtitulo {
    final partes = [rangoFechas, diasTexto].where((s) => s.isNotEmpty);
    return partes.join(' · ');
  }

  static String _corta(DateTime? fecha) {
    if (fecha == null) return '';
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }
}
