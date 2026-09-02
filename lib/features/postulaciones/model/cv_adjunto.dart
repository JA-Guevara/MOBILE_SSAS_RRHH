import 'dart:typed_data';

/// Archivo de hoja de vida elegido por el candidato (T1-20).
///
/// Guarda los bytes en memoria (no la ruta) para que la pantalla funcione
/// igual en Android, iOS y web: en web no existe una ruta de archivo.
class CvAdjunto {
  /// Tamaño máximo aceptado por el portal: 5 MB.
  static const int maxBytes = 5 * 1024 * 1024;

  /// Extensiones permitidas por la tarea.
  static const List<String> extensionesPermitidas = ['pdf', 'docx'];

  final String nombre;
  final Uint8List bytes;

  const CvAdjunto({required this.nombre, required this.bytes});

  int get tamanioBytes => bytes.length;

  /// Extensión en minúsculas, sin punto. "" si el nombre no tiene extensión.
  String get extension {
    final punto = nombre.lastIndexOf('.');
    if (punto == -1 || punto == nombre.length - 1) return '';
    return nombre.substring(punto + 1).toLowerCase();
  }

  bool get extensionValida => extensionesPermitidas.contains(extension);

  bool get pesoValido => tamanioBytes <= maxBytes;

  /// Content-Type que se manda en el multipart, según la extensión.
  String get mimeType => switch (extension) {
    'pdf' => 'application/pdf',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => 'application/octet-stream',
  };

  /// Tamaño legible para mostrar en la tarjeta: "1.2 MB", "840 KB".
  String get tamanioLegible => formatearTamanio(tamanioBytes);

  /// Igual que [tamanioLegible], pero sirve antes de leer el archivo:
  /// el selector conoce el peso sin cargar los bytes en memoria.
  static String formatearTamanio(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).round()} KB';
  }
}
