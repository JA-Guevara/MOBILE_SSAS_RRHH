import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// Una fila de la tabla "contrato" del diagrama del Sprint 3 (T3-01).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API para esta
/// tabla. Lee SOLO sus columnas:
///   id, empresa_id, empleado_id, cargo_id, departamento_id,
///   jefe_directo_id, contrato_anterior_id, numero_contrato, tipo_contrato,
///   modalidad, jornada, salario_basico, moneda, fecha_inicio, fecha_fin,
///   motivo_cambio, documento_url, estado, fecha_registro
///
/// Los contratos son versionados: cada cambio cierra el vigente y abre uno
/// nuevo enlazado por contrato_anterior_id. Por eso [esVigente] importa.
class Contrato {
  final String id;
  final String? empresaId;
  final String? empleadoId;
  final String? cargoId;
  final String? departamentoId;
  final String? jefeDirectoId;
  final String? contratoAnteriorId;
  final String? numeroContrato;

  /// INDEFINIDO / PLAZO_FIJO / EVENTUAL / CONSULTORIA / PASANTIA.
  final String? tipoContrato;

  final String? modalidad;

  /// TIEMPO_COMPLETO / MEDIO_TIEMPO / POR_HORAS.
  final String? jornada;

  final double? salarioBasico;
  final String? moneda;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? motivoCambio;
  final String? documentoUrl;

  /// VIGENTE / FINALIZADO.
  final String? estado;

  final DateTime? fechaRegistro;

  const Contrato({
    required this.id,
    this.empresaId,
    this.empleadoId,
    this.cargoId,
    this.departamentoId,
    this.jefeDirectoId,
    this.contratoAnteriorId,
    this.numeroContrato,
    this.tipoContrato,
    this.modalidad,
    this.jornada,
    this.salarioBasico,
    this.moneda,
    this.fechaInicio,
    this.fechaFin,
    this.motivoCambio,
    this.documentoUrl,
    this.estado,
    this.fechaRegistro,
  });

  factory Contrato.fromJson(Map<String, dynamic> json) => Contrato(
    id: leerId(json['id']) ?? '',
    empresaId: leerId(json['empresa_id']),
    empleadoId: leerId(json['empleado_id']),
    cargoId: leerId(json['cargo_id']),
    departamentoId: leerId(json['departamento_id']),
    jefeDirectoId: leerId(json['jefe_directo_id']),
    contratoAnteriorId: leerId(json['contrato_anterior_id']),
    numeroContrato: json['numero_contrato'] as String?,
    tipoContrato: json['tipo_contrato'] as String?,
    modalidad: json['modalidad'] as String?,
    jornada: json['jornada'] as String?,
    // Numeric de Postgres puede llegar como número o como texto "6500.00".
    salarioBasico: double.tryParse('${json['salario_basico']}'),
    moneda: json['moneda'] as String?,
    fechaInicio: _fecha(json['fecha_inicio']),
    fechaFin: _fecha(json['fecha_fin']),
    motivoCambio: json['motivo_cambio'] as String?,
    documentoUrl: json['documento_url'] as String?,
    estado: json['estado'] as String?,
    fechaRegistro: _fecha(json['fecha_registro']),
  );

  static DateTime? _fecha(Object? valor) =>
      valor == null ? null : DateTime.tryParse(valor.toString());

  /// True si es el contrato en curso. Un contrato sin estado se toma como
  /// vigente para no esconder a nadie por un dato que falta.
  bool get esVigente {
    final e = (estado ?? '').trim().toUpperCase();
    return e.isEmpty || e == 'VIGENTE';
  }
}
