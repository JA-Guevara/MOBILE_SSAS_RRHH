import 'dart:typed_data';

import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';

/// Documento de respaldo de una solicitud de ausencia (T3-19): el
/// certificado médico, la constancia del trámite...
///
/// Es como CvAdjunto (T1-20), pero acepta fotos: un certificado médico casi
/// siempre se sube como foto tomada con el teléfono.
class DocumentoAdjunto {
  /// Mismo límite que el CV del portal: 5 MB.
  static const int maxBytes = CvAdjunto.maxBytes;

  static const List<String> extensionesPermitidas = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];

  final String nombre;
  final Uint8List bytes;

  const DocumentoAdjunto({required this.nombre, required this.bytes});

  /// Extensión en minúsculas, sin punto. "" si el nombre no tiene extensión.
  String get extension {
    final punto = nombre.lastIndexOf('.');
    if (punto == -1 || punto == nombre.length - 1) return '';
    return nombre.substring(punto + 1).toLowerCase();
  }

  /// Content-Type que se manda en el multipart, según la extensión.
  String get mimeType => switch (extension) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    _ => 'application/octet-stream',
  };

  String get tamanioLegible => CvAdjunto.formatearTamanio(bytes.length);
}
