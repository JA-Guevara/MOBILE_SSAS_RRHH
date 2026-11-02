import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/model/mes_trabajado.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Un día del mes: fecha, entrada y salida, horas y lo que haya que notar
/// (retraso, horas extra, salida sin marcar).
///
/// Ubicación:  lib/features/mis_dias/ui/widgets/dia_trabajado_card.dart
class DiaTrabajadoCard extends StatelessWidget {
  final Asistencia dia;
  final EstadoDia estado;

  const DiaTrabajadoCard({super.key, required this.dia, required this.estado});

  @override
  Widget build(BuildContext context) {
    final fecha = dia.fecha;
    final retraso = dia.minutosRetraso ?? 0;
    final extra = dia.horasExtra ?? 0;
    final notas = <String>[
      if (retraso > 0) '$retraso min tarde',
      if (extra > 0) '+${MesTrabajado.horas(extra)} extra',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.carta,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha == null ? '—' : MesTrabajado.etiquetaDia(fecha),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tinta,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dia.resumenHoras,
                  style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
                ),
                if (notas.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notas.join(' · '),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ambar700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          switch (estado) {
            EstadoDia.completo => Text(
              dia.horasTrabajadas == null
                  ? ''
                  : MesTrabajado.horas(dia.horasTrabajadas!),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.tinta,
              ),
            ),
            EstadoDia.enJornada => const _Chip(
              texto: 'En jornada',
              fondo: AppColors.azul100,
              color: AppColors.azul700,
            ),
            EstadoDia.sinSalida => const _Chip(
              texto: 'Sin salida',
              fondo: AppColors.ambar100,
              color: AppColors.ambar700,
            ),
          },
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;

  const _Chip({required this.texto, required this.fondo, required this.color});

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
