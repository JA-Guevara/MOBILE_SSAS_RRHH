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

  /// >>> VERIFICA contra /docs <<<  La tabla guarda periodo_id; aquí se
  /// espera el periodo ya resuelto, porque la lista se agrupa por él y el
  /// colaborador no ve identificadores.
  final PeriodoNomina? periodo;

  /// Las líneas de la boleta, ya ordenadas por secuencia. Vienen vacías en
  /// la lista y llenas en el detalle: el listado no necesita cargarlas.
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

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory BoletaPago.fromJson(Map<String, dynamic> json) {
    // El backend puede devolver el objeto directo o envuelto, igual que en
    // las otras features.
    final cuerpo =
        (json['data'] ?? json['boleta'] ?? json) as Map<String, dynamic>;

    final periodoJson = cuerpo['periodo'];
    final listaDetalles = (cuerpo['detalles'] ?? const []) as List;

    final detalles =
        listaDetalles
            .whereType<Map<String, dynamic>>()
            .map(BoletaDetalle.fromJson)
            .toList()
          // El orden lo manda "secuencia": es como la empresa quiere que se
          // lea su boleta. Se ordena aquí para que la pantalla no dependa
          // de que el backend lo respete.
          ..sort((a, b) => a.secuencia.compareTo(b.secuencia));

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
      periodo: periodoJson is Map<String, dynamic>
          ? PeriodoNomina.fromJson(periodoJson)
          : null,
      detalles: detalles,
    );
  }

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
