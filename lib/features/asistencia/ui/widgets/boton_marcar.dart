import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// El botón grande de la maqueta: un círculo verde100 de 130 px con el botón
/// verde600 de 104 px dentro.
///
/// El texto y si está habilitado dependen de qué falta por marcar hoy:
///   entrada  -> "Marcar entrada"
///   salida   -> "Marcar salida"
///   ninguna  -> "Jornada cerrada", deshabilitado
///
/// Ubicación:  lib/features/asistencia/ui/widgets/boton_marcar.dart
class BotonMarcar extends StatelessWidget {
  final MarcaPendiente pendiente;

  /// True mientras se pide el GPS o viaja la petición: todo bloqueado.
  final bool ocupado;

  final VoidCallback onMarcar;

  const BotonMarcar({
    super.key,
    required this.pendiente,
    required this.ocupado,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    final cerrado = pendiente == MarcaPendiente.ninguna;
    final habilitado = !cerrado && !ocupado;

    return Container(
      width: 130,
      height: 130,
      decoration: const BoxDecoration(
        color: AppColors.verde100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 104,
          height: 104,
          child: ElevatedButton(
            onPressed: habilitado ? onMarcar : null,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              // Cuando está deshabilitado, Material lo pinta gris por su
              // cuenta; se le da un gris de los tokens para no salirse.
              disabledBackgroundColor: AppColors.verde300,
              disabledForegroundColor: Colors.white,
            ),
            child: ocupado
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _texto(pendiente),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.25),
                  ),
          ),
        ),
      ),
    );
  }

  /// El salto de línea es el de la maqueta: "Marcar" arriba, "entrada" abajo.
  static String _texto(MarcaPendiente pendiente) => switch (pendiente) {
    MarcaPendiente.entrada => 'Marcar\nentrada',
    MarcaPendiente.salida => 'Marcar\nsalida',
    MarcaPendiente.ninguna => 'Jornada\ncerrada',
  };
}
