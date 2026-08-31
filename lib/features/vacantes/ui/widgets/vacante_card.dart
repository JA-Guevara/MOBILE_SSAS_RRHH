import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';

/// Tarjeta de una vacante, según la maqueta móvil de la guía:
/// título, "modalidad · ciudad", y "Cierra {fecha}".
///
/// Ubicación sugerida:  lib/features/vacantes/ui/widgets/vacante_card.dart
class VacanteCard extends StatelessWidget {
  final Vacante vacante;
  final VoidCallback? onTap;

  const VacanteCard({super.key, required this.vacante, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.carta,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        side: const BorderSide(color: AppColors.borde),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vacante.titulo,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 17,
                  color: AppColors.tinta,
                ),
              ),
              if (vacante.subtitulo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  vacante.subtitulo,
                  style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
                ),
              ],
              if (vacante.fechaCierreCorta.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.crema,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Cierra ${vacante.fechaCierreCorta}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.ambar700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
