import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/nueva_solicitud.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Campo de fecha con el aspecto de CampoFormulario (T1-20): al tocarlo
/// abre el calendario. Es un FormField para que el Form lo valide junto con
/// los demás campos y pinte el error debajo, igual que un texto.
///
/// Ubicación:  lib/features/solicitudes/ui/widgets/campo_fecha.dart
class CampoFecha extends StatelessWidget {
  final String etiqueta;
  final DateTime? valor;

  /// Abre el calendario. La pantalla decide los límites (desde cuándo y
  /// hasta cuándo se puede elegir).
  final VoidCallback? onTap;

  final String? Function(DateTime?)? validador;

  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onTap,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EtiquetaCampo(texto: etiqueta, obligatorio: true),
        const SizedBox(height: 6),
        FormField<DateTime>(
          // Se reconstruye con el valor nuevo: initialValue solo se lee al
          // crear el estado, y la fecha la elige la pantalla.
          key: ValueKey(valor),
          initialValue: valor,
          validator: validador,
          builder: (estado) => InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.boton),
            child: InputDecorator(
              decoration: decoracionCampo().copyWith(
                errorText: estado.errorText,
                errorMaxLines: 3,
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.tinta2,
                ),
              ),
              child: Text(
                valor == null
                    ? 'dd/mm/aaaa'
                    : NuevaSolicitud.fechaCorta(valor!),
                style: TextStyle(
                  fontSize: 14,
                  color: valor == null ? AppColors.tinta2 : AppColors.tinta,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
