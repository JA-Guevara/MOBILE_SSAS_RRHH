import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/equipo/model/miembro_equipo.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Tarjeta de una persona del equipo: iniciales, nombre, cargo y cómo está
/// hoy. SOLO LECTURA: sin onTap, la gestión vive en la web.
///
/// Ubicación:  lib/features/equipo/ui/widgets/miembro_card.dart
class MiembroCard extends StatelessWidget {
  final MiembroEquipo miembro;

  const MiembroCard({super.key, required this.miembro});

  @override
  Widget build(BuildContext context) {
    final cargo = miembro.cargo;

    return Card(
      color: AppColors.carta,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        side: const BorderSide(color: AppColors.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.verde100,
              child: Text(
                miembro.iniciales,
                style: const TextStyle(
                  color: AppColors.verde600,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    miembro.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tinta,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cargo ?? 'Sin cargo asignado',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.tinta2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    miembro.detalleDia,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.tinta2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ChipEstadoDia(estado: miembro.estadoDia),
          ],
        ),
      ),
    );
  }
}

/// Chip del estado del día, con los colores de la guía: verde en jornada,
/// azul (informativo) ya salió, ámbar sin marcar y rojo ausente.
class ChipEstadoDia extends StatelessWidget {
  final EstadoDia estado;

  const ChipEstadoDia({super.key, required this.estado});

  /// El texto del chip. Lo usa también el resumen de la pantalla.
  static String etiqueta(EstadoDia estado) => switch (estado) {
    EstadoDia.enJornada => 'En jornada',
    EstadoDia.salio => 'Salió',
    EstadoDia.sinMarcar => 'Sin marcar',
    EstadoDia.ausente => 'Ausente',
  };

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = switch (estado) {
      EstadoDia.enJornada => (AppColors.verde100, AppColors.verde600),
      EstadoDia.salio => (AppColors.azul100, AppColors.azul700),
      EstadoDia.sinMarcar => (AppColors.ambar100, AppColors.ambar700),
      EstadoDia.ausente => (AppColors.rojo100, AppColors.rojo700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiqueta(estado),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: texto,
        ),
      ),
    );
  }
}
