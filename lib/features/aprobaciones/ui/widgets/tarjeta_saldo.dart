import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// El saldo de vacaciones del solicitante (T3-22).
///
/// Solo se muestra cuando el tipo de ausencia descuenta vacación: en los
/// demás casos el saldo no cambia y enseñarlo sería ruido.
///
/// Si los días pedidos superan el saldo, la tarjeta se pone en rojo. El jefe
/// puede aprobar igual —esa es su decisión—, pero no puede decir que no lo
/// sabía.
///
/// Ubicación:  lib/features/aprobaciones/ui/widgets/tarjeta_saldo.dart
class TarjetaSaldo extends StatelessWidget {
  final SaldoVacacion saldo;
  final double? diasSolicitados;

  const TarjetaSaldo({
    super.key,
    required this.saldo,
    required this.diasSolicitados,
  });

  @override
  Widget build(BuildContext context) {
    final alcanza = saldo.alcanzaPara(diasSolicitados);

    final fondo = alcanza ? AppColors.verde100 : AppColors.rojo100;
    final tinte = alcanza ? AppColors.verde600 : AppColors.rojo700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alcanza ? Icons.beach_access_outlined : Icons.error_outline,
            size: 18,
            color: tinte,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo de vacaciones'
                  '${saldo.gestion != null ? ' · gestión ${saldo.gestion}' : ''}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: tinte,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  saldo.resumen,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tinte,
                  ),
                ),
                if (!alcanza && diasSolicitados != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pide ${SaldoVacacion.dias(diasSolicitados!)} días: '
                    'son más de los que tiene.',
                    style: TextStyle(fontSize: 12, height: 1.35, color: tinte),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
