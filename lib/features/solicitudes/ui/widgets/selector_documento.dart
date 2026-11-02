import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/documento_adjunto.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Botón "Adjuntar documento" + tarjeta del archivo elegido (T3-19).
///
/// Sigue a SelectorCv de T1-20: rechaza aquí mismo la extensión o el peso
/// que no sirven, para no gastar una subida; el backend vuelve a validar.
/// Solo se muestra cuando el tipo de ausencia tiene requiere_documento.
///
/// Ubicación:  lib/features/solicitudes/ui/widgets/selector_documento.dart
class SelectorDocumento extends StatefulWidget {
  final DocumentoAdjunto? documento;
  final ValueChanged<DocumentoAdjunto?> onCambio;

  /// Error que viene de afuera: se intentó enviar sin documento.
  final String? error;
  final bool habilitado;

  const SelectorDocumento({
    super.key,
    required this.documento,
    required this.onCambio,
    this.error,
    this.habilitado = true,
  });

  @override
  State<SelectorDocumento> createState() => _SelectorDocumentoState();
}

class _SelectorDocumentoState extends State<SelectorDocumento> {
  /// Error propio del selector (archivo pesado / extensión no permitida).
  String? _errorArchivo;

  Future<void> _elegirArchivo() async {
    setState(() => _errorArchivo = null);

    final PlatformFile? archivo;
    try {
      archivo = await FilePicker.pickFile(
        dialogTitle: 'Elige el documento de respaldo',
        type: FileType.custom,
        allowedExtensions: DocumentoAdjunto.extensionesPermitidas,
      );
    } on PlatformException catch (e) {
      _mostrarError('No se pudo abrir el explorador de archivos: ${e.message}');
      return;
    }

    // El usuario canceló: no se toca lo que ya había elegido.
    if (archivo == null) return;

    // El filtro del selector no es fiable en todas las plataformas.
    final extension = (archivo.extension ?? '').toLowerCase();
    if (!DocumentoAdjunto.extensionesPermitidas.contains(extension)) {
      _mostrarError(
        'Solo se aceptan PDF, JPG o PNG. '
        'Elegiste un archivo ${extension.isEmpty ? "sin extensión" : ".$extension"}.',
      );
      return;
    }

    // Se mide el peso ANTES de leer los bytes, como en SelectorCv.
    final int tamanio;
    final Uint8List bytes;
    try {
      tamanio = await archivo.length();
      if (tamanio > DocumentoAdjunto.maxBytes) {
        _mostrarError(
          'El archivo pesa ${CvAdjunto.formatearTamanio(tamanio)} '
          'y el máximo permitido es 5 MB.',
        );
        return;
      }
      bytes = await archivo.readAsBytes();
    } on Exception {
      _mostrarError('No se pudo leer el archivo. Intenta con otro.');
      return;
    }

    if (!mounted) return;
    setState(() => _errorArchivo = null);
    widget.onCambio(DocumentoAdjunto(nombre: archivo.name, bytes: bytes));
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    widget.onCambio(null);
    setState(() => _errorArchivo = mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final documento = widget.documento;
    final error = _errorArchivo ?? widget.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtiquetaCampo(
          texto: 'Documento de respaldo',
          obligatorio: true,
          ayuda: 'PDF, JPG o PNG · máx 5 MB',
        ),
        const SizedBox(height: 6),
        if (documento == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.habilitado ? _elegirArchivo : null,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Adjuntar documento'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.carta,
                foregroundColor: AppColors.verde600,
                side: const BorderSide(color: AppColors.borde),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.boton),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          _TarjetaArchivo(
            documento: documento,
            onQuitar: widget.habilitado
                ? () {
                    widget.onCambio(null);
                    setState(() => _errorArchivo = null);
                  }
                : null,
          ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(fontSize: 11.5, color: AppColors.rojo700),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta blanca con el archivo ya elegido: nombre, peso y quitar.
class _TarjetaArchivo extends StatelessWidget {
  final DocumentoAdjunto documento;
  final VoidCallback? onQuitar;

  const _TarjetaArchivo({required this.documento, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.carta,
        borderRadius: BorderRadius.circular(AppRadii.boton),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.verde100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 18,
              color: AppColors.verde600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documento.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.tinta),
                ),
                const SizedBox(height: 2),
                Text(
                  '${documento.extension.toUpperCase()} · '
                  '${documento.tamanioLegible}',
                  style: const TextStyle(fontSize: 11, color: AppColors.tinta2),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onQuitar,
            tooltip: 'Quitar archivo',
            icon: const Icon(Icons.close, size: 18, color: AppColors.tinta2),
          ),
        ],
      ),
    );
  }
}
