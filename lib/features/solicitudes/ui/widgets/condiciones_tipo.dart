import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Las condiciones del tipo de ausencia elegido, que el colaborador tiene
/// que saber ANTES de enviar: si descuenta de sus vacaciones, si tiene que
/// adjuntar documento, si es con goce de haber y el tope anual.
///
/// Ubicación:  lib/features/solicitudes/ui/widgets/condiciones_tipo.dart
class CondicionesTipo extends StatelessWidget {
  final TipoAusencia tipo;

  const CondicionesTipo({super.key, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final maximo = tipo.diasMaximosAnio;
    final chips = <Widget>[
      if (tipo.descuentaVacacion)
        const ChipCondicion(
          texto: 'Descuenta de tus vacaciones',
          fondo: AppColors.verde100,
          color: AppColors.verde600,
        ),
      if (tipo.requiereDocumento)
        const ChipCondicion(
          texto: 'Requiere documento',
          fondo: AppColors.ambar100,
          color: AppColors.ambar700,
        ),
      if (!tipo.esRemunerado)
        const ChipCondicion(
          texto: 'Sin goce de haber',
          fondo: AppColors.ambar100,
          color: AppColors.ambar700,
        ),
      if (maximo != null)
        ChipCondicion(
          texto: maximo == 1
              ? 'Hasta 1 día al año'
              : 'Hasta $maximo días al año',
          fondo: AppColors.azul100,
          color: AppColors.azul700,
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}

/// Chip pequeño con una condición del tipo de ausencia.
class ChipCondicion extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;

  const ChipCondicion({
    super.key,
    required this.texto,
    required this.fondo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
