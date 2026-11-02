import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// El periodo de nómina al que pertenece una boleta (T3-20).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Campos de la tabla "periodo_nomina" del diagrama:
///   id, empresa_id, nombre, mes, gestion, fecha_inicio, fecha_fin,
///   estado, fecha_cierre
class PeriodoNomina {
  final String id;
  final String? empresaId;
  final String? nombre;
  final int? mes;
  final int? gestion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? estado;
  final DateTime? fechaCierre;

  const PeriodoNomina({
    required this.id,
    this.empresaId,
    this.nombre,
    this.mes,
    this.gestion,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    this.fechaCierre,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory PeriodoNomina.fromJson(Map<String, dynamic> json) {
    return PeriodoNomina(
      id: leerId(json['id']) ?? '',
      empresaId: leerId(json['empresa_id']),
      nombre: json['nombre'] as String?,
      mes: (json['mes'] as num?)?.toInt(),
      gestion: (json['gestion'] as num?)?.toInt(),
      fechaInicio: _parseFecha(json['fecha_inicio']),
      fechaFin: _parseFecha(json['fecha_fin']),
      estado: json['estado'] as String?,
      fechaCierre: _parseFecha(json['fecha_cierre']),
    );
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Cómo se llama el periodo en pantalla: "Agosto 2026".
  ///
  /// Si el backend manda "nombre" se respeta tal cual, porque puede traer
  /// periodos que no son mensuales ("Aguinaldo 2026"). Solo si viene vacío
  /// se arma con mes y gestión.
  String get etiqueta {
    final propio = nombre?.trim() ?? '';
    if (propio.isNotEmpty) return propio;

    final m = mes;
    final g = gestion;
    if (m != null && g != null) return '${nombreDeMes(m)} $g';
    if (g != null) return '$g';
    return 'Periodo $id';
  }

  /// 1 -> "Enero". Fuera de rango devuelve "Mes $numero" en vez de reventar.
  static String nombreDeMes(int numero) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    if (numero < 1 || numero > 12) return 'Mes $numero';
    return meses[numero - 1];
  }
}
