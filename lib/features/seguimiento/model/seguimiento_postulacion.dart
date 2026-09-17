import 'package:mobile_ssas_rrhh/features/seguimiento/model/etapa_postulacion.dart';

/// Estado de una postulación consultada con su código de seguimiento (T2-18).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Campos tomados de la tabla "postulacion" del diagrama de clases:
///   id, vacante_id, postulante_id, etapa_id, motivo_rechazo_id, puntaje_ia,
///   puntaje_manual, notas, fecha_postulacion, fecha_ultimo_cambio, estado
class SeguimientoPostulacion {
  final int id;
  final String codigoSeguimiento;

  /// >>> VERIFICA contra /docs <<<  La tabla "postulacion" solo guarda
  /// vacante_id, pero la pantalla necesita el título y el nombre de la
  /// empresa. El endpoint público debería devolverlos ya resueltos.
  final String vacanteTitulo;
  final String empresaNombre;

  final String? estado;
  final double? puntajeIa;
  final double? puntajeManual;
  final String? notas;
  final DateTime? fechaPostulacion;
  final DateTime? fechaUltimoCambio;

  /// >>> VERIFICA contra /docs <<<  La tabla guarda motivo_rechazo_id; aquí
  /// se espera el nombre ya resuelto, porque el candidato no ve identificadores.
  final String? motivoRechazo;

  /// Etapas en orden, de la primera a la última del proceso.
  final List<EtapaPostulacion> etapas;

  const SeguimientoPostulacion({
    required this.id,
    required this.codigoSeguimiento,
    required this.vacanteTitulo,
    required this.empresaNombre,
    required this.etapas,
    this.estado,
    this.puntajeIa,
    this.puntajeManual,
    this.notas,
    this.fechaPostulacion,
    this.fechaUltimoCambio,
    this.motivoRechazo,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory SeguimientoPostulacion.fromJson(Map<String, dynamic> json) {
    // El backend puede devolver el objeto directo o envuelto en
    // {"data": {...}} / {"postulacion": {...}}. Cubrimos los tres casos,
    // igual que ResultadoPostulacion en T1-20.
    final cuerpo =
        (json['data'] ?? json['postulacion'] ?? json) as Map<String, dynamic>;

    final List listaEtapas =
        (cuerpo['etapas'] ?? cuerpo['historial'] ?? const []) as List;

    final etapas =
        listaEtapas
            .map((e) => EtapaPostulacion.fromJson(e as Map<String, dynamic>))
            .toList()
          // La línea de tiempo se dibuja de arriba abajo: respetamos "orden"
          // aunque el backend mande las etapas desordenadas.
          ..sort((a, b) => a.orden.compareTo(b.orden));

    return SeguimientoPostulacion(
      id: (cuerpo['id'] as num?)?.toInt() ?? 0,
      codigoSeguimiento: (cuerpo['codigo_seguimiento'] ?? '').toString(),
      vacanteTitulo: _anidado(cuerpo, 'vacante', 'titulo', 'vacante_titulo'),
      empresaNombre: _anidado(cuerpo, 'empresa', 'nombre', 'empresa_nombre'),
      estado: cuerpo['estado'] as String?,
      puntajeIa: (cuerpo['puntaje_ia'] as num?)?.toDouble(),
      puntajeManual: (cuerpo['puntaje_manual'] as num?)?.toDouble(),
      notas: cuerpo['notas'] as String?,
      fechaPostulacion: _parseFecha(cuerpo['fecha_postulacion']),
      fechaUltimoCambio: _parseFecha(cuerpo['fecha_ultimo_cambio']),
      motivoRechazo: _motivoRechazo(cuerpo),
      etapas: etapas,
    );
  }

  /// Lee un dato que puede venir plano ("vacante_titulo") o anidado
  /// ("vacante": {"titulo": ...}). Devuelve "" si no está en ninguno.
  static String _anidado(
    Map<String, dynamic> cuerpo,
    String objeto,
    String campo,
    String plano,
  ) {
    final directo = cuerpo[plano];
    if (directo != null) return directo.toString();

    final sub = cuerpo[objeto];
    if (sub is Map && sub[campo] != null) return sub[campo].toString();

    return '';
  }

  static String? _motivoRechazo(Map<String, dynamic> cuerpo) {
    final directo = cuerpo['motivo_rechazo'];
    if (directo is String && directo.isNotEmpty) return directo;
    if (directo is Map && directo['nombre'] != null) {
      return directo['nombre'].toString();
    }
    return null;
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Subtítulo de la cabecera del contenido: el nombre de la empresa.
  /// Se separa en un getter para que la pantalla no arme textos a mano.
  String get subtitulo => empresaNombre;

  /// True si el proceso terminó con un rechazo: la última etapa alcanzada
  /// está marcada como es_rechazado en etapa_reclutamiento.
  bool get fueRechazada =>
      etapas.any((e) => e.alcanzada && e.esRechazado) ||
      (motivoRechazo != null && motivoRechazo!.isNotEmpty);
}
