/// Respuesta del backend al registrar una postulación (T1-20).
///
/// Lo único imprescindible es el CÓDIGO DE SEGUIMIENTO (ej. TX-8F4K2): con él
/// el candidato consulta su estado desde la web o la app.
///
/// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
class ResultadoPostulacion {
  final String codigoSeguimiento; // <- codigo_seguimiento
  final String? mensaje;

  const ResultadoPostulacion({required this.codigoSeguimiento, this.mensaje});

  factory ResultadoPostulacion.fromJson(Map<String, dynamic> json) {
    // El backend puede devolver el objeto directo o envuelto en
    // {"data": {...}} / {"postulacion": {...}}. Cubrimos los tres casos.
    final cuerpo =
        (json['data'] ?? json['postulacion'] ?? json) as Map<String, dynamic>;

    final codigo =
        cuerpo['codigo_seguimiento'] ??
        cuerpo['codigo'] ??
        cuerpo['tracking_code'];

    return ResultadoPostulacion(
      codigoSeguimiento: (codigo ?? '').toString(),
      mensaje: cuerpo['mensaje'] as String?,
    );
  }
}
