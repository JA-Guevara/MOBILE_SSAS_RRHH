import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// "Hoy · 08:03 a 17:12" y la nota de la maqueta.
/// Cuando todavía no hay marcas sale "Hoy · —:— a —:—".
///
/// Ubicación:  lib/features/asistencia/ui/widgets/resumen_dia.dart
class ResumenDia extends StatelessWidget {
  /// Null cuando el colaborador aún no marcó nada hoy.
  final Asistencia? asistencia;

  const ResumenDia({super.key, this.asistencia});

  @override
  Widget build(BuildContext context) {
    final marca = asistencia;
    final entrada = marca?.entradaCorta ?? Asistencia.sinHora;
    final salida = marca?.salidaCorta ?? Asistencia.sinHora;

    return Column(
      children: [
        // "Hoy · 08:03 a 17:12" con las horas en negrita, como la maqueta.
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.tinta),
            children: [
              const TextSpan(text: 'Hoy · '),
              TextSpan(
                text: entrada,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' a '),
              TextSpan(
                text: salida,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Captura lat/long al marcar · una marca por día',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.tinta2),
        ),
        if (marca != null && marca.diaCompleto) ...[
          const SizedBox(height: 14),
          _Totales(asistencia: marca),
        ],
      ],
    );
  }
}

/// Cuando el día está cerrado, el backend ya calculó las horas. Mostrarlas
/// evita que el colaborador tenga que abrir la web para verlas.
class _Totales extends StatelessWidget {
  final Asistencia asistencia;

  const _Totales({required this.asistencia});

  @override
  Widget build(BuildContext context) {
    final partes = <String>[
      if (asistencia.horasTrabajadas != null)
        '${_horas(asistencia.horasTrabajadas!)} trabajadas',
      if ((asistencia.horasExtra ?? 0) > 0)
        '${_horas(asistencia.horasExtra!)} extra',
      if ((asistencia.minutosRetraso ?? 0) > 0)
        '${asistencia.minutosRetraso} min de retraso',
    ];

    if (partes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.circular(AppRadii.boton),
        border: Border.all(color: AppColors.ambar100),
      ),
      child: Text(
        partes.join(' · '),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: AppColors.ambar700),
      ),
    );
  }

  /// 9.15 -> "9.15 h". El backend manda horas decimales, no "9h 09m".
  /// >>> VERIFICA contra /docs <<<  Si horas_trabajadas viene en minutos o
  /// como texto "09:09", este formateo es lo único que hay que cambiar.
  static String _horas(double valor) {
    final texto = valor.toStringAsFixed(2);
    return '${texto.endsWith('.00') ? valor.toStringAsFixed(0) : texto} h';
  }
}
