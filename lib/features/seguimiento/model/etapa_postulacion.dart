/// Un hito de la línea de tiempo (T2-18): una etapa del proceso de
/// reclutamiento y, si ya se recorrió, cuándo ocurrió.
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
/// Si el backend usa otros nombres de campo, solo cambias las claves dentro
/// de fromJson y toda la app se adapta sola. La pantalla nunca lee el JSON
/// directamente: usa este modelo.
///
/// Campos tomados de la tabla "etapa_reclutamiento" del diagrama de clases:
///   id, nombre, orden, color, es_inicial, es_contratado, es_rechazado
class EtapaPostulacion {
  final int id;
  final String nombre;
  final int orden;
  final bool esInicial;
  final bool esContratado;
  final bool esRechazado;

  /// Color que la empresa configuró para la etapa (etapa_reclutamiento.color).
  /// Se lee para no perder el dato del contrato, pero la pantalla NO lo pinta:
  /// la regla del equipo es que solo existen los colores de AppColors.
  final String? color;

  /// >>> VERIFICA contra /docs <<<  Si la etapa ya fue recorrida.
  /// Si el backend no manda este campo, se deduce de que traiga fecha.
  final bool alcanzada;

  /// >>> VERIFICA contra /docs <<<  Fecha y hora en que se alcanzó la etapa.
  final DateTime? fecha;

  /// >>> VERIFICA contra /docs <<<  Nota corta del hito, tal como la maqueta:
  /// "afinidad IA 81%", "virtual". Null en las etapas que aún no ocurren.
  final String? detalle;

  const EtapaPostulacion({
    required this.id,
    required this.nombre,
    required this.orden,
    this.esInicial = false,
    this.esContratado = false,
    this.esRechazado = false,
    this.color,
    this.alcanzada = false,
    this.fecha,
    this.detalle,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  factory EtapaPostulacion.fromJson(Map<String, dynamic> json) {
    final fecha = _parseFecha(json['fecha']);

    return EtapaPostulacion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '') as String,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      esInicial: json['es_inicial'] == true,
      esContratado: json['es_contratado'] == true,
      esRechazado: json['es_rechazado'] == true,
      color: json['color'] as String?,
      // Si el backend no manda "alcanzada", una etapa con fecha ya ocurrió.
      alcanzada: json['alcanzada'] as bool? ?? (fecha != null),
      fecha: fecha,
      detalle: json['detalle'] as String?,
    );
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Fecha lista para mostrar como "20/08". Devuelve "" si no hay fecha.
  String get fechaCorta {
    final f = fecha;
    if (f == null) return '';
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  /// Hora como "14:02". Devuelve "" si no hay fecha o si viene a medianoche:
  /// en ese caso el backend registró solo el día, no la hora exacta.
  String get horaCorta {
    final f = fecha;
    if (f == null) return '';
    if (f.hour == 0 && f.minute == 0) return '';
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$hh:$mi';
  }

  /// Segunda línea del hito, como en la maqueta:
  ///   "20/08 · 14:02"              fecha con hora
  ///   "22/08 · afinidad IA 81%"    fecha sin hora + detalle
  ///   "26/08 · 10:00 · virtual"    fecha, hora y detalle
  /// Devuelve "" en las etapas futuras, que no llevan segunda línea.
  String get subtitulo {
    final partes = [
      fechaCorta,
      horaCorta,
      detalle ?? '',
    ].where((s) => s.isNotEmpty);
    return partes.join(' · ');
  }
}
