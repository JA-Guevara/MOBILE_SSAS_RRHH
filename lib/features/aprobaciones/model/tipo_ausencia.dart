import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// El tipo de ausencia que se solicita: vacación, baja médica, permiso... (T3-22)
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Campos de la tabla "tipo_ausencia" del diagrama:
///   id, empresa_id, nombre, codigo, es_remunerado, descuenta_vacacion,
///   dias_maximos_anio, requiere_aprobacion, requiere_documento, activo
class TipoAusencia {
  final String id;
  final String? empresaId;
  final String nombre;
  final String? codigo;
  final bool esRemunerado;

  /// Si es true, los días aprobados salen del saldo de vacaciones. Es lo que
  /// decide si al jefe se le enseña el saldo del empleado.
  final bool descuentaVacacion;

  final int? diasMaximosAnio;
  final bool requiereAprobacion;

  /// Si es true, la solicitud debería traer documento_url. El jefe tiene que
  /// poder ver que falta antes de aprobar.
  final bool requiereDocumento;

  final bool activo;

  const TipoAusencia({
    required this.id,
    required this.nombre,
    this.empresaId,
    this.codigo,
    this.esRemunerado = true,
    this.descuentaVacacion = false,
    this.diasMaximosAnio,
    this.requiereAprobacion = true,
    this.requiereDocumento = false,
    this.activo = true,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory TipoAusencia.fromJson(Map<String, dynamic> json) {
    return TipoAusencia(
      id: leerId(json['id']) ?? '',
      empresaId: leerId(json['empresa_id']),
      nombre: (json['nombre'] ?? '') as String,
      codigo: json['codigo'] as String?,
      // Los booleanos se leen con == true a propósito: si el backend manda
      // null, el valor seguro es false, no reventar.
      esRemunerado: json['es_remunerado'] == true,
      descuentaVacacion: json['descuenta_vacacion'] == true,
      diasMaximosAnio: (json['dias_maximos_anio'] as num?)?.toInt(),
      requiereAprobacion: json['requiere_aprobacion'] == true,
      requiereDocumento: json['requiere_documento'] == true,
      activo: json['activo'] != false,
    );
  }

  /// El cuerpo para guardar los cambios del administrador (T3-30): las
  /// columnas editables de la tabla. Sin id (va en la ruta) ni empresa_id
  /// (el backend la saca del token).
  Map<String, Object?> toJson() => {
    'nombre': nombre,
    'codigo': codigo,
    'es_remunerado': esRemunerado,
    'descuenta_vacacion': descuentaVacacion,
    'dias_maximos_anio': diasMaximosAnio,
    'requiere_aprobacion': requiereAprobacion,
    'requiere_documento': requiereDocumento,
    'activo': activo,
  };

  /// "Vacación · no remunerado" o solo "Vacación". Lo que se muestra bajo
  /// el nombre del solicitante.
  String get subtitulo {
    final partes = <String>[
      if (!esRemunerado) 'no remunerado',
      if (descuentaVacacion) 'descuenta vacación',
    ];
    return partes.join(' · ');
  }
}
