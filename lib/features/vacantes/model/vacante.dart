/// Modelo de una vacante pública.
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
/// Si el backend usa otros nombres de campo (p. ej. "fechaCierre" en vez de
/// "fecha_cierre"), solo cambias las claves dentro de fromJson y toda la app
/// se adapta sola. La pantalla nunca lee el JSON directamente: usa este modelo.
///
/// Ubicación sugerida:  lib/features/vacantes/model/vacante.dart
class Vacante {
  final int id;
  final String titulo;
  final String? modalidad;
  final String? ubicacion;
  final DateTime? fechaCierre;
  
  // Nuevos campos para el detalle (T1-19)
  final String? descripcion;
  final List<String>? requisitos;
  final List<String>? beneficios;
  final double? salario;

  const Vacante({
    required this.id,
    required this.titulo,
    this.modalidad,
    this.ubicacion,
    this.fechaCierre,
    this.descripcion,
    this.requisitos,
    this.beneficios,
    this.salario,
  });

  /// Construye una Vacante a partir del JSON del backend.
  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory Vacante.fromJson(Map<String, dynamic> json) {
    return Vacante(
      id: (json['id'] as num).toInt(),
      titulo: (json['titulo'] ?? '') as String,
      modalidad: json['modalidad'] as String?,
      ubicacion: json['ubicacion'] as String?,
      fechaCierre: _parseFecha(json['fecha_cierre']),
      descripcion: json['descripcion'] as String?,
      // Mapeo seguro de listas
      requisitos: (json['requisitos'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      beneficios: (json['beneficios'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      // El salario puede venir null o como número
      salario: (json['salario'] as num?)?.toDouble(),
    );
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Fecha lista para mostrar como "10/09". Devuelve "" si no hay fecha.
  String get fechaCierreCorta {
    final f = fechaCierre;
    if (f == null) return '';
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  /// Subtítulo de la tarjeta: "Híbrido · Santa Cruz". Omite lo que falte.
  String get subtitulo {
    final partes = [
      modalidad,
      ubicacion,
    ].where((s) => s != null && s.isNotEmpty);
    return partes.join(' · ');
  }
}