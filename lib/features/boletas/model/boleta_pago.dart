import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_detalle.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/periodo_nomina.dart';
import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// La boleta de pago de un periodo (T3-20 · HU-14 · CU-27).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Campos de la tabla "boleta_pago" del diagrama:
///   id, empresa_id, periodo_id, empleado_id, contrato_id, estructura_id,
///   numero, dias_trabajados, dias_no_trabajados, horas_extra,
///   salario_basico, total_ganado, total_descuentos, liquido_pagable,
///   total_aportes_patronales, estado, fecha_generacion, fecha_pago
class BoletaPago {
  final String id;
  final String? empresaId;
  final String? periodoId;
  final String? empleadoId;
  final String? contratoId;
  final String? estructuraId;
  final String? numero;

  final int? diasTrabajados;
  final int? diasNoTrabajados;
  final double? horasExtra;

  final double? salarioBasico;
  final double? totalGanado;
  final double? totalDescuentos;
  final double? liquidoPagable;
  final double? totalAportesPatronales;

  final String? estado;
  final DateTime? fechaGeneracion;
  final DateTime? fechaPago;

  /// La fila de periodo_nomina cuyo id es [periodoId]. NO viene en el JSON
  /// de la boleta: la resuelve BoletasService con [conRelaciones].
  final PeriodoNomina? periodo;

  /// Las filas de boleta_detalle cuyo boleta_id es [id], ordenadas por
  /// secuencia. Vacías en la lista y llenas en el detalle: las une
  /// BoletasService con [conRelaciones].
  final List<BoletaDetalle> detalles;

  const BoletaPago({
    required this.id,
    this.empresaId,
    this.periodoId,
    this.empleadoId,
    this.contratoId,
    this.estructuraId,
    this.numero,
    this.diasTrabajados,
    this.diasNoTrabajados,
    this.horasExtra,
    this.salarioBasico,
    this.totalGanado,
    this.totalDescuentos,
    this.liquidoPagable,
    this.totalAportesPatronales,
    this.estado,
    this.fechaGeneracion,
    this.fechaPago,
    this.periodo,
    this.detalles = const [],
  });

  /// Lee SOLO las columnas de la tabla "boleta_pago" del diagrama. El
  /// periodo y las líneas se unen después con [conRelaciones].
  factory BoletaPago.fromJson(Map<String, dynamic> cuerpo) {
    return BoletaPago(
      id: leerId(cuerpo['id']) ?? '',
      empresaId: leerId(cuerpo['empresa_id']),
      periodoId: leerId(cuerpo['periodo_id']),
      empleadoId: leerId(cuerpo['empleado_id']),
      contratoId: leerId(cuerpo['contrato_id']),
      estructuraId: leerId(cuerpo['estructura_id']),
      numero: cuerpo['numero']?.toString(),
      diasTrabajados: (cuerpo['dias_trabajados'] as num?)?.toInt(),
      diasNoTrabajados: (cuerpo['dias_no_trabajados'] as num?)?.toInt(),
      horasExtra: (cuerpo['horas_extra'] as num?)?.toDouble(),
      salarioBasico: (cuerpo['salario_basico'] as num?)?.toDouble(),
      totalGanado: (cuerpo['total_ganado'] as num?)?.toDouble(),
      totalDescuentos: (cuerpo['total_descuentos'] as num?)?.toDouble(),
      liquidoPagable: (cuerpo['liquido_pagable'] as num?)?.toDouble(),
      totalAportesPatronales: (cuerpo['total_aportes_patronales'] as num?)
          ?.toDouble(),
      estado: cuerpo['estado'] as String?,
      fechaGeneracion: _parseFecha(cuerpo['fecha_generacion']),
      fechaPago: _parseFecha(cuerpo['fecha_pago']),
    );
  }

  /// La misma boleta con su periodo y sus líneas ya unidos.
  ///
  /// Las líneas se ordenan por "secuencia": es como la empresa quiere que
  /// se lea su boleta. Se ordena aquí para que la pantalla no dependa de
  /// que el backend lo respete.
  BoletaPago conRelaciones({
    PeriodoNomina? periodo,
    List<BoletaDetalle>? detalles,
  }) => BoletaPago(
    id: id,
    empresaId: empresaId,
    periodoId: periodoId,
    empleadoId: empleadoId,
    contratoId: contratoId,
    estructuraId: estructuraId,
    numero: numero,
    diasTrabajados: diasTrabajados,
    diasNoTrabajados: diasNoTrabajados,
    horasExtra: horasExtra,
    salarioBasico: salarioBasico,
    totalGanado: totalGanado,
    totalDescuentos: totalDescuentos,
    liquidoPagable: liquidoPagable,
    totalAportesPatronales: totalAportesPatronales,
    estado: estado,
    fechaGeneracion: fechaGeneracion,
    fechaPago: fechaPago,
    periodo: periodo ?? this.periodo,
    detalles: detalles == null
        ? this.detalles
        : ([...detalles]..sort((a, b) => a.secuencia.compareTo(b.secuencia))),
  );

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Título de la tarjeta y de la cabecera del detalle: "Agosto 2026".
  String get etiquetaPeriodo => periodo?.etiqueta ?? 'Boleta ${numero ?? id}';

  /// Las líneas de un grupo, en el orden que fijó la empresa.
  /// El orden ya viene de fromJson, así que filtrar lo conserva.
  List<BoletaDetalle> lineasDe(TipoDetalle tipo) =>
      detalles.where((d) => d.tipo == tipo).toList(growable: false);

  List<BoletaDetalle> get haberes => lineasDe(TipoDetalle.haber);
  List<BoletaDetalle> get descuentos => lineasDe(TipoDetalle.descuento);

  /// Líneas cuyo "tipo" no supimos interpretar. Si esta lista no está vacía,
  /// hay que revisar los literales del backend contra parseTipo.
  List<BoletaDetalle> get otras => lineasDe(TipoDetalle.otro);

  /// "13 días trabajados · 2 no trabajados". Omite lo que falte.
  String get resumenDias {
    final partes = <String>[
      if (diasTrabajados != null) '$diasTrabajados días trabajados',
      if ((diasNoTrabajados ?? 0) > 0) '$diasNoTrabajados no trabajados',
    ];
    return partes.join(' · ');
  }
}
