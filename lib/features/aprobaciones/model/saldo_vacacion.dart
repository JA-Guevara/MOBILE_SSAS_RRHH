import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// El saldo de vacaciones del empleado en una gestión (T3-22).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Campos de la tabla "saldo_vacacion" del diagrama:
///   id, empleado_id, gestion, dias_asignados, dias_usados, dias_saldo,
///   fecha_corte, fecha_actualizacion
class SaldoVacacion {
  final String id;
  final String? empleadoId;
  final int? gestion;
  final double? diasAsignados;
  final double? diasUsados;
  final double? diasSaldo;
  final DateTime? fechaCorte;
  final DateTime? fechaActualizacion;

  const SaldoVacacion({
    required this.id,
    this.empleadoId,
    this.gestion,
    this.diasAsignados,
    this.diasUsados,
    this.diasSaldo,
    this.fechaCorte,
    this.fechaActualizacion,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  ///
  /// Los días se leen como double porque medio día de vacación es habitual.
  /// Si el backend los guarda como enteros, esto sigue funcionando.
  factory SaldoVacacion.fromJson(Map<String, dynamic> json) {
    return SaldoVacacion(
      id: leerId(json['id']) ?? '',
      empleadoId: leerId(json['empleado_id']),
      gestion: (json['gestion'] as num?)?.toInt(),
      diasAsignados: (json['dias_asignados'] as num?)?.toDouble(),
      diasUsados: (json['dias_usados'] as num?)?.toDouble(),
      diasSaldo: (json['dias_saldo'] as num?)?.toDouble(),
      fechaCorte: _parseFecha(json['fecha_corte']),
      fechaActualizacion: _parseFecha(json['fecha_actualizacion']),
    );
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// "8 de 15 días disponibles". Devuelve "" si no hay datos suficientes.
  String get resumen {
    final saldo = diasSaldo;
    if (saldo == null) return '';

    final asignados = diasAsignados;
    if (asignados == null) return '${dias(saldo)} días disponibles';
    return '${dias(saldo)} de ${dias(asignados)} días disponibles';
  }

  /// 8.0 -> "8".  8.5 -> "8,5". Los días enteros no llevan decimales.
  static String dias(double valor) {
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor.toString().replaceFirst('.', ',');
  }

  /// True si al empleado no le alcanza el saldo para lo que pide.
  /// El jefe puede aprobar igual, pero tiene que verlo antes.
  bool alcanzaPara(double? diasSolicitados) {
    final saldo = diasSaldo;
    if (saldo == null || diasSolicitados == null) return true;
    return saldo >= diasSolicitados;
  }
}
