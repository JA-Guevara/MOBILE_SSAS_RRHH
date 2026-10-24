import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// Un documento del legajo digital del colaborador (T3-27 · HU-12 · CU-20).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Los campos son los de la tabla "documento_empleado" del diagrama
/// (T3-01 y T3-02):
///   id, empleado_id, tipo, nombre, archivo_url, fecha_emision,
///   fecha_vencimiento, fecha_carga
class DocumentoEmpleado {
  final String id;
  final String? empleadoId;

  /// Uno de CI / TITULO / CERTIFICADO / CONTRATO / EXAMEN_MEDICO /
  /// ANTECEDENTES / OTRO. Se guarda tal cual llega; [tipoEtiqueta] lo
  /// traduce para la pantalla.
  final String tipo;

  final String nombre;
  final String? archivoUrl;
  final DateTime? fechaEmision;

  /// Null cuando el documento no vence (un título, un CI sin fecha...).
  final DateTime? fechaVencimiento;

  final DateTime? fechaCarga;

  /// Días de anticipación con los que se avisa que un documento va a
  /// vencer. La tarea no fija el número; 30 días da margen para renovar un
  /// examen médico o un certificado de antecedentes.
  static const diasAviso = 30;

  const DocumentoEmpleado({
    required this.id,
    required this.tipo,
    required this.nombre,
    this.empleadoId,
    this.archivoUrl,
    this.fechaEmision,
    this.fechaVencimiento,
    this.fechaCarga,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  /// El endpoint todavía no existe (T3-02 solo cubre el legajo de la web).
  factory DocumentoEmpleado.fromJson(Map<String, dynamic> json) {
    return DocumentoEmpleado(
      id: leerId(json['id']) ?? '',
      empleadoId: leerId(json['empleado_id']),
      tipo: (json['tipo'] ?? 'OTRO').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      // T3-02 llama "archivo" a la columna; el contrato de T3-27 la llama
      // "archivo_url". Se aceptan las dos.
      archivoUrl: _texto(json['archivo_url'] ?? json['archivo']),
      fechaEmision: _fecha(json['fecha_emision']),
      fechaVencimiento: _fecha(json['fecha_vencimiento']),
      fechaCarga: _fecha(json['fecha_carga']),
    );
  }

  static DateTime? _fecha(Object? valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  static String? _texto(Object? valor) {
    if (valor == null) return null;
    final s = valor.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ---------------------------------------------------------------- vigencia

  /// Días que le quedan al documento contando desde [hoy]. Negativo si ya
  /// venció; null si no vence. Se comparan solo las fechas, sin la hora:
  /// un documento que vence hoy tiene 0 días y todavía vale.
  int? diasRestantes(DateTime hoy) {
    final vence = fechaVencimiento;
    if (vence == null) return null;
    // Se usa UTC para que un cambio de horario no reste o sume un día.
    return DateTime.utc(
      vence.year,
      vence.month,
      vence.day,
    ).difference(DateTime.utc(hoy.year, hoy.month, hoy.day)).inDays;
  }

  /// En qué situación está el documento en la fecha [hoy].
  Vigencia vigencia(DateTime hoy) {
    final dias = diasRestantes(hoy);
    if (dias == null) return Vigencia.sinVencimiento;
    if (dias < 0) return Vigencia.vencido;
    if (dias <= diasAviso) return Vigencia.porVencer;
    return Vigencia.vigente;
  }

  /// "Vence en 12 días", "Vence hoy", "Venció hace 3 días"...
  /// Devuelve "" si el documento no vence.
  String avisoVencimiento(DateTime hoy) {
    final dias = diasRestantes(hoy);
    if (dias == null) return '';
    if (dias == 0) return 'Vence hoy';
    if (dias == 1) return 'Vence mañana';
    if (dias > 1) return 'Vence en $dias días';
    if (dias == -1) return 'Venció ayer';
    return 'Venció hace ${-dias} días';
  }

  /// Orden de la lista: primero lo que pide acción (vencidos y por vencer,
  /// el más urgente arriba), después los vigentes y al final los que no
  /// vencen. Dentro de cada grupo, por nombre, para que no baile al recargar.
  static int Function(DocumentoEmpleado, DocumentoEmpleado) porUrgencia(
    DateTime hoy,
  ) {
    return (a, b) {
      final ga = a.vigencia(hoy).index;
      final gb = b.vigencia(hoy).index;
      if (ga != gb) return ga.compareTo(gb);
      final da = a.diasRestantes(hoy);
      final db = b.diasRestantes(hoy);
      if (da != null && db != null && da != db) return da.compareTo(db);
      return a.nombre.compareTo(b.nombre);
    };
  }

  // ------------------------------------------------------------- para mostrar

  /// "CI" -> "Carnet de identidad". Si llega un tipo nuevo, se muestra el
  /// literal del backend en vez de esconderlo.
  String get tipoEtiqueta => switch (tipo.trim().toUpperCase()) {
    'CI' => 'Carnet de identidad',
    'TITULO' => 'Título',
    'CERTIFICADO' => 'Certificado',
    'CONTRATO' => 'Contrato',
    'EXAMEN_MEDICO' => 'Examen médico',
    'ANTECEDENTES' => 'Antecedentes',
    'OTRO' => 'Otro',
    _ => tipo,
  };

  String get emisionCorta => fechaLarga(fechaEmision);
  String get vencimientoCorto => fechaLarga(fechaVencimiento);

  /// "05/03/2027". Devuelve "" si no hay fecha. Lleva el año porque un
  /// vencimiento puede estar a varios años de distancia.
  static String fechaLarga(DateTime? f) {
    if (f == null) return '';
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    return '$dd/$mm/${f.year}';
  }
}

/// Situación de un documento. El orden importa: es el orden de la lista.
enum Vigencia { vencido, porVencer, vigente, sinVencimiento }
