/// Modelo de una vacante pública.
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
/// Si el backend usa otros nombres de campo (p. ej. "fechaCierre" en vez de
/// "fecha_cierre"), solo cambias las claves dentro de fromJson y toda la app
/// se adapta sola. La pantalla nunca lee el JSON directamente: usa este modelo.
///
/// Modelo de una vacante pública adaptado al esquema de FastAPI.
class Vacante {
  // 1. Ahora el ID es String para soportar UUIDs
  final String id; 
  final String titulo;
  final String? modalidad;
  final String? ubicacion;
  final DateTime? fechaCierre;
  
  final String? descripcion;
  // 2. Requisitos y beneficios ahora son String (bloques de texto)
  final String? requisitos; 
  final String? beneficios; 
  
  // 3. Mapeo fiel de los salarios
  final double? salarioMin;
  final double? salarioMax;
  final bool mostrarSalario;

  const Vacante({
    required this.id,
    required this.titulo,
    this.modalidad,
    this.ubicacion,
    this.fechaCierre,
    this.descripcion,
    this.requisitos,
    this.beneficios,
    this.salarioMin,
    this.salarioMax,
    this.mostrarSalario = false,
  });

  /// Construye una Vacante a partir del JSON del backend.
  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory Vacante.fromJson(Map<String, dynamic> json) {
    return Vacante(
      // Se castea como String directamente
      id: json['id'].toString(),
      titulo: (json['titulo'] ?? '') as String,
      modalidad: json['modalidad'] as String?,
      ubicacion: json['ubicacion'] as String?,
      fechaCierre: _parseFecha(json['fecha_cierre']),
      descripcion: json['descripcion'] as String?,
      requisitos: _parseTextoOLista(json['requisitos']),
      beneficios: _parseTextoOLista(json['beneficios']),
      // Manejo seguro de números que vienen de un Decimal en Python
      salarioMin: (json['salario_min'] as num?)?.toDouble(),
      salarioMax: (json['salario_max'] as num?)?.toDouble(),
      mostrarSalario: json['mostrar_salario'] as bool? ?? false,
    );
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  static String? _parseTextoOLista(dynamic valor) {
    if (valor == null) return null;
    if (valor is String) return valor;
    if (valor is List) return valor.join('\n'); // Une la lista con saltos de línea
    return valor.toString();
  }

  String get fechaCierreCorta {
    final f = fechaCierre;
    if (f == null) return '';
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  String get subtitulo {
    final partes = [
      modalidad,
      ubicacion,
    ].where((s) => s != null && s.isNotEmpty);
    return partes.join(' · ');
  }
}