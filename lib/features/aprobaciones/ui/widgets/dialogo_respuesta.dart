import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Qué va a hacer el jefe.
enum AccionRespuesta { aprobar, rechazar }

/// Diálogo de confirmación antes de responder una solicitud (T3-22).
///
/// Aprobar y rechazar son IRREVERSIBLES desde el móvil, así que no se
/// ejecutan de un solo toque: este diálogo es la confirmación.
///
/// La observación es obligatoria al rechazar y opcional al aprobar. Un
/// rechazo sin motivo deja al empleado sin saber qué corregir.
///
/// Devuelve la observación escrita, o null si el jefe canceló. Ojo: al
/// aprobar sin escribir nada devuelve la cadena vacía, que NO es lo mismo
/// que null.
///
/// Ubicación:  lib/features/aprobaciones/ui/widgets/dialogo_respuesta.dart
Future<String?> mostrarDialogoRespuesta(
  BuildContext context, {
  required AccionRespuesta accion,
  required String solicitante,
  required String resumen,
}) {
  return showDialog<String>(
    context: context,
    // No se cierra tocando fuera: es una decisión, no un aviso.
    barrierDismissible: false,
    builder: (_) => _DialogoRespuesta(
      accion: accion,
      solicitante: solicitante,
      resumen: resumen,
    ),
  );
}

class _DialogoRespuesta extends StatefulWidget {
  final AccionRespuesta accion;
  final String solicitante;
  final String resumen;

  const _DialogoRespuesta({
    required this.accion,
    required this.solicitante,
    required this.resumen,
  });

  @override
  State<_DialogoRespuesta> createState() => _DialogoRespuestaState();
}

class _DialogoRespuestaState extends State<_DialogoRespuesta> {
  final _observacion = TextEditingController();

  /// Solo se reclama la observación después de intentar confirmar, para no
  /// pintar de rojo un diálogo recién abierto.
  var _autovalidar = false;

  bool get _esRechazo => widget.accion == AccionRespuesta.rechazar;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  String? get _error {
    if (!_esRechazo) return null;
    if (!_autovalidar) return null;
    if (_observacion.text.trim().isEmpty) {
      return 'Explica por qué la rechazas.';
    }
    return null;
  }

  void _confirmar() {
    setState(() => _autovalidar = true);
    if (_error != null) return;
    Navigator.of(context).pop(_observacion.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tinte = _esRechazo ? AppColors.rojo700 : AppColors.verde600;

    return AlertDialog(
      backgroundColor: AppColors.carta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
      ),
      title: Text(
        _esRechazo ? '¿Rechazar la solicitud?' : '¿Aprobar la solicitud?',
        style: const TextStyle(
          fontFamily: 'serif',
          fontSize: 19,
          color: AppColors.tinta,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.solicitante} · ${widget.resumen}',
            style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Observación',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tinta,
                ),
              ),
              if (_esRechazo)
                const Text(
                  ' *',
                  style: TextStyle(fontSize: 12.5, color: AppColors.rojo700),
                )
              else
                const Text(
                  '  opcional',
                  style: TextStyle(fontSize: 11, color: AppColors.tinta2),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _observacion,
            autofocus: _esRechazo,
            maxLines: 3,
            maxLength: 500,
            onChanged: (_) {
              // Con el error en pantalla, se limpia en cuanto escribe.
              if (_autovalidar) setState(() {});
            },
            style: const TextStyle(fontSize: 14, color: AppColors.tinta),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.carta,
              counterText: '',
              hintText: _esRechazo
                  ? 'Motivo del rechazo, para que el empleado sepa qué pasó'
                  : 'Algo que quieras dejar anotado',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.tinta2),
              errorText: _error,
              errorStyle: const TextStyle(
                fontSize: 11.5,
                color: AppColors.rojo700,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: _borde(AppColors.borde),
              enabledBorder: _borde(AppColors.borde),
              focusedBorder: _borde(tinte, ancho: 1.6),
              errorBorder: _borde(AppColors.rojo700),
              focusedErrorBorder: _borde(AppColors.rojo700, ancho: 1.6),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Esta decisión no se puede deshacer desde el móvil.',
            style: TextStyle(fontSize: 11.5, color: AppColors.tinta2),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.tinta2),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(backgroundColor: tinte),
          child: Text(_esRechazo ? 'Rechazar' : 'Aprobar'),
        ),
      ],
    );
  }

  static OutlineInputBorder _borde(Color color, {double ancho = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.boton),
      borderSide: BorderSide(color: color, width: ancho),
    );
  }
}
