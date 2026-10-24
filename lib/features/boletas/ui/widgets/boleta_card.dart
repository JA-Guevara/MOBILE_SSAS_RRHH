import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_pago.dart';
import 'package:mobile_ssas_rrhh/shared/format/moneda.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Tarjeta de una boleta en la lista: periodo, número, estado y el líquido
/// pagable, que es lo único que el colaborador busca de un vistazo.
///
/// Ubicación:  lib/features/boletas/ui/widgets/boleta_card.dart
class BoletaCard extends StatelessWidget {
  final BoletaPago boleta;
  final VoidCallback? onTap;

  const BoletaCard({super.key, required this.boleta, this.onTap});

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boleta.etiquetaPeriodo,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        color: AppColors.tinta,
                      ),
                    ),
                    if (boleta.numero != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        boleta.numero!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.tinta2,
                        ),
                      ),
                    ],
                    if (boleta.estado != null) ...[
                      const SizedBox(height: 10),
                      ChipEstadoBoleta(estado: boleta.estado!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Líquido',
                    style: TextStyle(fontSize: 11, color: AppColors.tinta2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Moneda.bs(boleta.liquidoPagable),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.verde600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip del estado de la boleta, con la clase .chip de la guía.
///
/// >>> VERIFICA contra /docs <<<  Los literales de boleta_pago.estado son
/// una suposición: "pagada", "generada", "anulada". Lo que no se reconozca
/// sale en ámbar, que la guía usa para "pendiente".
class ChipEstadoBoleta extends StatelessWidget {
  final String estado;

  const ChipEstadoBoleta({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = _colores(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _etiqueta(estado),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: texto,
        ),
      ),
    );
  }

  static (Color, Color) _colores(String estado) =>
      switch (estado.trim().toLowerCase()) {
        'pagada' || 'pagado' => (AppColors.verde100, AppColors.verde600),
        'anulada' || 'anulado' => (AppColors.rojo100, AppColors.rojo700),
        _ => (AppColors.ambar100, AppColors.ambar700),
      };

  /// "pagada" -> "Pagada". Se muestra el valor del backend con la primera
  /// letra en mayúscula, sin traducirlo: si aparece algo raro, se ve.
  static String _etiqueta(String estado) {
    final v = estado.trim();
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1).toLowerCase();
  }
}
