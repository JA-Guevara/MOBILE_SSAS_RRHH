import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Botón "Subir CV desde el teléfono" + tarjeta del archivo elegido.
///
/// Rechaza aquí mismo lo que no cumple (extensión o peso) para no gastar
/// una subida al backend; aun así el backend vuelve a validar.
class SelectorCv extends StatefulWidget {
  final CvAdjunto? cv;
  final ValueChanged<CvAdjunto?> onCambio;

  /// Mensaje de error que viene de afuera (se envió sin CV, o el backend
  /// rechazó el archivo).
  final String? error;
  final bool habilitado;

  const SelectorCv({
    super.key,
    required this.cv,
    required this.onCambio,
    this.error,
    this.habilitado = true,
  });

  @override
  State<SelectorCv> createState() => _SelectorCvState();
}

class _SelectorCvState extends State<SelectorCv> {
  /// Error propio del selector (archivo pesado / extensión no permitida).
  String? _errorArchivo;

  Future<void> _elegirArchivo() async {
    setState(() => _errorArchivo = null);

    final PlatformFile? archivo;
    try {
      archivo = await FilePicker.pickFile(
        dialogTitle: 'Elige tu hoja de vida',
        type: FileType.custom,
        allowedExtensions: CvAdjunto.extensionesPermitidas,
      );
    } on PlatformException catch (e) {
      _mostrarError('No se pudo abrir el explorador de archivos: ${e.message}');
      return;
    }

    // El usuario canceló: no se toca lo que ya había elegido.
    if (archivo == null) return;

    // El filtro de extensiones del selector no es fiable en todas las
    // plataformas, así que lo volvemos a comprobar aquí.
    final extension = (archivo.extension ?? '').toLowerCase();
    if (!CvAdjunto.extensionesPermitidas.contains(extension)) {
      _mostrarError(
        'Solo se aceptan archivos PDF o DOCX. '
        'Elegiste un archivo ${extension.isEmpty ? "sin extensión" : ".$extension"}.',
      );
      return;
    }

    // Se mide el peso ANTES de leer los bytes: así un archivo de 200 MB no
    // entra a memoria solo para ser rechazado.
    final int tamanio;
    final Uint8List bytes;
    try {
      tamanio = await archivo.length();
      if (tamanio > CvAdjunto.maxBytes) {
        _mostrarError(
          'El archivo pesa ${CvAdjunto.formatearTamanio(tamanio)} '
          'y el máximo permitido es 5 MB. '
          'Comprime el PDF o sube una versión más liviana.',
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
    widget.onCambio(CvAdjunto(nombre: archivo.name, bytes: bytes));
  }

  /// Deja el formulario sin CV y muestra el motivo del rechazo.
  void _mostrarError(String mensaje) {
    if (!mounted) return;
    widget.onCambio(null);
    setState(() => _errorArchivo = mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final cv = widget.cv;
    final error = _errorArchivo ?? widget.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EtiquetaCampo(
            texto: 'Hoja de vida',
            obligatorio: true,
            ayuda: 'PDF/DOCX · máx 5 MB',
          ),
          const SizedBox(height: 6),
          if (cv == null)
            _BotonSubir(onPressed: widget.habilitado ? _elegirArchivo : null)
          else
            _TarjetaArchivo(
              cv: cv,
              onCambiar: widget.habilitado ? _elegirArchivo : null,
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
      ),
    );
  }
}

/// Botón secundario de la guía: fondo blanco, borde suave, texto verde.
class _BotonSubir extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BotonSubir({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.upload_file_outlined, size: 18),
        label: const Text('Subir CV desde el teléfono'),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.carta,
          foregroundColor: AppColors.verde600,
          side: const BorderSide(color: AppColors.borde),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.boton),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Tarjeta blanca con el archivo ya elegido: nombre, peso y acciones.
class _TarjetaArchivo extends StatelessWidget {
  final CvAdjunto cv;
  final VoidCallback? onCambiar;
  final VoidCallback? onQuitar;

  const _TarjetaArchivo({
    required this.cv,
    required this.onCambiar,
    required this.onQuitar,
  });

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
                  cv.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.tinta),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cv.extension.toUpperCase()} · ${cv.tamanioLegible}',
                  style: const TextStyle(fontSize: 11, color: AppColors.tinta2),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCambiar,
            style: TextButton.styleFrom(foregroundColor: AppColors.verde600),
            child: const Text('Cambiar', style: TextStyle(fontSize: 12.5)),
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
