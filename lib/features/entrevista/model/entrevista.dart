/// Entrevista programada para una postulación (T2-19 · HU-08 · CU-15).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// >>> VERIFICA contra /docs <<<  El backend TODAVÍA NO TIENE entrevistas
/// (depende de T2-02: no hay tabla, esquema ni ruta). Las claves de abajo
/// son una propuesta del equipo móvil; cuando rrhh-api publique el módulo,
/// se ajustan aquí y nada más de la app cambia.
class Entrevista {
  final int id;
  final String codigoSeguimiento;

  /// Título de la vacante, igual que el campo "vacante" de
  /// GET /publico/postulaciones/{codigo}, que ya existe.
  final String vacanteTitulo;

  final DateTime fechaHora;
  final int? duracionMinutos;
  final ModalidadEntrevista modalidad;

  /// Dirección, solo si es presencial.
  final String? lugar;

  /// Enlace de la videollamada, solo si es virtual.
  final String? enlace;

  final String? entrevistador;
  final EstadoEntrevista estado;

  /// Cuándo confirmó el postulante. null mientras no confirme.
  final DateTime? confirmadaEn;

  const Entrevista({
    required this.id,
    required this.codigoSeguimiento,
    required this.vacanteTitulo,
    required this.fechaHora,
    required this.modalidad,
    required this.estado,
    this.duracionMinutos,
    this.lugar,
    this.enlace,
    this.entrevistador,
    this.confirmadaEn,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory Entrevista.fromJson(Map<String, dynamic> json) {
    // Mismo criterio que SeguimientoPostulacion: objeto directo o envuelto
    // en {"data": {...}} / {"entrevista": {...}}.
    final cuerpo =
        (json['data'] ?? json['entrevista'] ?? json) as Map<String, dynamic>;

    return Entrevista(
      id: (cuerpo['id'] as num?)?.toInt() ?? 0,
      codigoSeguimiento: (cuerpo['codigo_seguimiento'] ?? '').toString(),
      vacanteTitulo: (cuerpo['vacante'] ?? cuerpo['vacante_titulo'] ?? '')
          .toString(),
      fechaHora: _parseFecha(cuerpo['fecha_hora']) ?? DateTime.now(),
      duracionMinutos: (cuerpo['duracion_minutos'] as num?)?.toInt(),
      modalidad: ModalidadEntrevista.desde(cuerpo['modalidad']),
      lugar: _textoONull(cuerpo['lugar']),
      enlace: _textoONull(cuerpo['enlace']),
      entrevistador: _textoONull(cuerpo['entrevistador']),
      estado: EstadoEntrevista.desde(cuerpo['estado']),
      confirmadaEn: _parseFecha(cuerpo['confirmada_en']),
    );
  }

  static String? _textoONull(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  /// El backend manda timestamptz ("...Z" o "+00:00"): se pasa a hora local
  /// para que el postulante vea la hora de su teléfono.
  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString())?.toLocal();
  }

  /// Solo se confirma una entrevista programada que todavía no pasó.
  bool get puedeConfirmar =>
      estado == EstadoEntrevista.programada &&
      fechaHora.isAfter(DateTime.now());

  bool get yaPaso => fechaHora.isBefore(DateTime.now());

  /// "Viernes 10/10/2026".
  String get fechaLarga {
    final f = fechaHora;
    return '${_dias[f.weekday - 1]} ${_dosDigitos(f.day)}/'
        '${_dosDigitos(f.month)}/${f.year}';
  }

  /// "15:00 · 45 min" o solo "15:00".
  String get horaTexto {
    final hora =
        '${_dosDigitos(fechaHora.hour)}:${_dosDigitos(fechaHora.minute)}';
    return duracionMinutos == null ? hora : '$hora · $duracionMinutos min';
  }

  static const _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static String _dosDigitos(int n) => n.toString().padLeft(2, '0');
}

enum ModalidadEntrevista {
  presencial('Presencial'),
  virtual('Virtual');

  final String etiqueta;

  const ModalidadEntrevista(this.etiqueta);

  /// Acepta "virtual", "VIRTUAL", etc. Si no la reconoce, presencial.
  static ModalidadEntrevista desde(dynamic valor) {
    final texto = (valor ?? '').toString().toLowerCase();
    return texto == 'virtual'
        ? ModalidadEntrevista.virtual
        : ModalidadEntrevista.presencial;
  }
}

enum EstadoEntrevista {
  programada('Por confirmar'),
  confirmada('Asistencia confirmada'),
  reprogramada('Reprogramada'),
  cancelada('Cancelada');

  final String etiqueta;

  const EstadoEntrevista(this.etiqueta);

  /// Acepta mayúsculas o minúsculas, como "estado" de la postulación
  /// (ACTIVA, RETIRADA...). Si no lo reconoce, la trata como programada.
  static EstadoEntrevista desde(dynamic valor) {
    final texto = (valor ?? '').toString().toLowerCase();
    return EstadoEntrevista.values.firstWhere(
      (e) => e.name == texto,
      orElse: () => EstadoEntrevista.programada,
    );
  }
}
