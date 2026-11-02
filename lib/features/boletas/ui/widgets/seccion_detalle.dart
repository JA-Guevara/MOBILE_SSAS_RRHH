import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_detalle.dart';
import 'package:mobile_ssas_rrhh/shared/format/moneda.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Un bloque del detalle: "HABERES" o "DESCUENTOS", sus líneas en el orden
/// que fijó la empresa, y el total del bloque.
///
/// Ubicación:  lib/features/boletas/ui/widgets/seccion_detalle.dart
class SeccionDetalle extends StatelessWidget {
  final String titulo;
  final List<BoletaDetalle> lineas;

  /// El total que manda el backend (total_ganado / total_descuentos). Se
  /// muestra ese, no la suma de las líneas: si no cuadran, manda el backend.
  final double? total;

  /// Los descuentos se pintan en rojo para que se distingan de un vistazo.
  final Color color;

  const SeccionDetalle({
    super.key,
    required this.titulo,
    required this.lineas,
    required this.total,
    this.color = AppColors.tinta,
  });

  @override
  Widget build(BuildContext context) {
    if (lineas.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carta,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.tinta2,
            ),
          ),
          const SizedBox(height: 10),
          for (final linea in lineas) _Fila(linea: linea, color: color),
          if (total != null) ...[
            const Divider(height: 22, color: AppColors.borde),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total $titulo'.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tinta,
                    ),
                  ),
                ),
                Text(
                  Moneda.bs(total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Una línea: nombre arriba, de dónde sale el monto abajo, importe a la
/// derecha.
class _Fila extends StatelessWidget {
  final BoletaDetalle linea;
  final Color color;

  const _Fila({required this.linea, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea.nombre,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.tinta,
                  ),
                ),
                if (linea.calculo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    linea.calculo,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.tinta2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Moneda.bs(linea.monto),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// El líquido pagable, que es lo que de verdad cobra el colaborador.
/// Va destacado al final, sobre franja crema como el código de T1-20.
class LiquidoPagable extends StatelessWidget {
  final double? monto;

  const LiquidoPagable({super.key, required this.monto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        border: Border.all(color: AppColors.ambar100),
      ),
      child: Column(
        children: [
          const Text(
            'LÍQUIDO PAGABLE',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
              color: AppColors.tinta2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Moneda.bs(monto),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.tinta,
            ),
          ),
        ],
      ),
    );
  }
}
