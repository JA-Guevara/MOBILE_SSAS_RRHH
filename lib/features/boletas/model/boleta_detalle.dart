import 'package:mobile_ssas_rrhh/shared/format/moneda.dart';
import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// En qué grupo de la boleta va una línea.
///
/// [otro] existe a propósito: si el backend manda un tipo que no
/// reconocemos (aportes patronales, por ejemplo), la línea se muestra en su
/// propio grupo en vez de desaparecer. Ocultar plata sin avisar sería peor
/// que enseñarla en un bloque que no esperábamos.
enum TipoDetalle { haber, descuento, otro }

/// Una línea de la boleta: un haber o un descuento (T3-20).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Campos de la tabla "boleta_detalle" del diagrama:
///   id, boleta_id, regla_id, codigo, nombre, tipo, secuencia,
///   cantidad, base, porcentaje, monto
class BoletaDetalle {
  final String id;
  final String? boletaId;
  final String? reglaId;
  final String? codigo;
  final String nombre;

  /// El tipo ya interpretado, que es por lo que se agrupa.
  final TipoDetalle tipo;

  /// Lo que mandó el backend en "tipo", tal cual. Se guarda para poder
  /// depurar cuando una línea cae en [TipoDetalle.otro].
  final String? tipoCrudo;

  /// Orden dentro de su grupo. Lo define la empresa en sus reglas.
  final int secuencia;

  final double? cantidad;
  final double? base;
  final double? porcentaje;
  final double? monto;

  const BoletaDetalle({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.secuencia,
    this.boletaId,
    this.reglaId,
    this.codigo,
    this.tipoCrudo,
    this.cantidad,
    this.base,
    this.porcentaje,
    this.monto,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory BoletaDetalle.fromJson(Map<String, dynamic> json) {
    final crudo = json['tipo']?.toString();

    return BoletaDetalle(
      id: leerId(json['id']) ?? '',
      boletaId: leerId(json['boleta_id']),
      reglaId: leerId(json['regla_id']),
      codigo: json['codigo'] as String?,
      nombre: (json['nombre'] ?? '') as String,
      tipo: parseTipo(crudo),
      tipoCrudo: crudo,
      secuencia: (json['secuencia'] as num?)?.toInt() ?? 0,
      cantidad: (json['cantidad'] as num?)?.toDouble(),
      base: (json['base'] as num?)?.toDouble(),
      porcentaje: (json['porcentaje'] as num?)?.toDouble(),
      monto: (json['monto'] as num?)?.toDouble(),
    );
  }

  /// >>> VERIFICA contra /docs <<<  No sabemos qué literales usa el backend
  /// en "tipo". Se aceptan las familias más probables en español; lo que no
  /// encaje cae en [TipoDetalle.otro] y se muestra igual.
  static TipoDetalle parseTipo(String? valor) {
    final v = (valor ?? '').trim().toLowerCase();
    if (v.isEmpty) return TipoDetalle.otro;

    if (v.startsWith('hab') || v.startsWith('ingres') || v.startsWith('gana')) {
      return TipoDetalle.haber;
    }
    if (v.startsWith('desc') ||
        v.startsWith('egres') ||
        v.startsWith('reten')) {
      return TipoDetalle.descuento;
    }
    return TipoDetalle.otro;
  }

  /// Segunda línea de la fila, que explica de dónde sale el monto:
  ///   "13 días"
  ///   "12,71% sobre Bs 4.500,00"
  ///   "Bs 4.500,00"
  /// Devuelve "" cuando el backend no mandó ninguno de los tres datos.
  String get calculo {
    final partes = <String>[];

    final c = cantidad;
    if (c != null && c != 0) {
      // Las cantidades enteras se muestran sin decimales: "13", no "13,00".
      partes.add(
        c == c.roundToDouble() ? '${c.round()}' : Moneda.sinSimbolo(c),
      );
    }

    final p = porcentaje;
    final b = base;
    if (p != null && p != 0) {
      partes.add(
        b != null && b != 0
            ? '${Moneda.porcentaje(p)} sobre ${Moneda.bs(b)}'
            : Moneda.porcentaje(p),
      );
    } else if (b != null && b != 0) {
      partes.add('sobre ${Moneda.bs(b)}');
    }

    return partes.join(' · ');
  }
}
