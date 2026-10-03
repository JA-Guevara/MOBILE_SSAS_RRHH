import 'package:mobile_ssas_rrhh/features/seguimiento/model/etapa_postulacion.dart';

/// Una fila del ranking de candidatos de una vacante (T2-20).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Cruza tres tablas del diagrama de clases:
///   postulante          -> nombres, apellidos, ciudad, anios_experiencia
///   postulacion         -> puntaje_ia, puntaje_manual, estado, etapa_id
///   etapa_reclutamiento -> nombre, orden, color  (a través de [etapa])
///
/// La etapa se modela con EtapaPostulacion, que ya traduce las columnas de
/// etapa_reclutamiento en T2-18. Se reutiliza a propósito: si las claves de
/// esa tabla vivieran en dos archivos, se rompería la regla del equipo de
/// que el modelo es el único lugar donde viven las claves del API.
class CandidatoRanking {
  /// Id de la postulacion, no del postulante: es lo que identifica la fila.
  final int id;

  final String nombres;
  final String apellidos;
  final String? ciudad;
  final int? aniosExperiencia;

  /// >>> VERIFICA contra /docs <<<  Se asume escala 0-100 (la maqueta muestra
  /// "87%"). Si el backend devuelve 0-1, hay que multiplicar por 100 aquí.
  final double? puntajeIa;

  final double? puntajeManual;
  final String? estado;

  /// >>> VERIFICA contra /docs <<<  La tabla guarda etapa_id; aquí se espera
  /// la etapa ya resuelta, porque la tarjeta muestra su nombre.
  final EtapaPostulacion? etapa;

  const CandidatoRanking({
    required this.id,
    required this.nombres,
    required this.apellidos,
    this.ciudad,
    this.aniosExperiencia,
    this.puntajeIa,
    this.puntajeManual,
    this.estado,
    this.etapa,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory CandidatoRanking.fromJson(Map<String, dynamic> json) {
    // Los datos del postulante pueden venir planos o anidados en
    // "postulante": {...}. Cubrimos los dos casos.
    final sub = json['postulante'];
    final postulante = sub is Map<String, dynamic> ? sub : json;

    final etapaJson = json['etapa'];

    return CandidatoRanking(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombres: (postulante['nombres'] ?? '') as String,
      apellidos: (postulante['apellidos'] ?? '') as String,
      ciudad: postulante['ciudad'] as String?,
      aniosExperiencia: (postulante['anios_experiencia'] as num?)?.toInt(),
      puntajeIa: (json['puntaje_ia'] as num?)?.toDouble(),
      puntajeManual: (json['puntaje_manual'] as num?)?.toDouble(),
      estado: json['estado'] as String?,
      etapa: etapaJson is Map<String, dynamic>
          ? EtapaPostulacion.fromJson(etapaJson)
          : null,
    );
  }

  /// "Julia Quispe". Si falta alguna parte, no deja espacios sueltos.
  String get nombreCompleto =>
      [nombres, apellidos].where((s) => s.isNotEmpty).join(' ');

  /// Segunda línea de la tarjeta: "Santa Cruz · 5 años". Omite lo que falte.
  String get subtitulo {
    final anios = aniosExperiencia;
    final partes = [
      ciudad ?? '',
      if (anios != null) anios == 1 ? '1 año' : '$anios años',
    ].where((s) => s.isNotEmpty);
    return partes.join(' · ');
  }

  /// True si la IA alcanzó a puntuar a este candidato. Según la guía, la
  /// insignia lila solo aparece cuando hay puntaje_ia; si no, no se dibuja.
  bool get tieneAfinidad => puntajeIa != null;

  /// La afinidad como "87%". Devuelve "" si la IA todavía no puntuó.
  String get afinidadTexto {
    final p = puntajeIa;
    if (p == null) return '';
    return '${p.round()}%';
  }

  /// Ordena de mayor a menor afinidad. Los candidatos que la IA todavía no
  /// puntuó van al final, y entre iguales se ordena por nombre para que la
  /// lista no baile entre recargas.
  static int porAfinidadDesc(CandidatoRanking a, CandidatoRanking b) {
    final pa = a.puntajeIa;
    final pb = b.puntajeIa;
    if (pa == null && pb == null) {
      return a.nombreCompleto.compareTo(b.nombreCompleto);
    }
    if (pa == null) return 1;
    if (pb == null) return -1;
    final cmp = pb.compareTo(pa);
    return cmp != 0 ? cmp : a.nombreCompleto.compareTo(b.nombreCompleto);
  }
}
