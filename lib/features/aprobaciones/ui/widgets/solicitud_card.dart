import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Tarjeta de una solicitud en la bandeja: quién pide, qué tipo, qué fechas
/// y cuántos días.
///
/// Ubicación:  lib/features/aprobaciones/ui/widgets/solicitud_card.dart
class SolicitudCard extends StatelessWidget {
  final SolicitudAusencia solicitud;
  final VoidCallback? onTap;

  const SolicitudCard({super.key, required this.solicitud, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tipo = solicitud.tipo;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          solicitud.solicitante,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 17,
                            color: AppColors.tinta,
                          ),
                        ),
                        if (solicitud.cargoSolicitante != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            solicitud.cargoSolicitante!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.tinta2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (tipo != null) ...[
                    const SizedBox(width: 10),
                    ChipTipoAusencia(nombre: tipo.nombre),
                  ],
                ],
              ),
              if (solicitud.subtitulo.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 15,
                      color: AppColors.tinta2,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      solicitud.subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.tinta,
                      ),
                    ),
                  ],
                ),
              ],
              // Dos avisos que el jefe necesita ver antes de entrar.
              if (solicitud.faltaDocumento) ...[
                const SizedBox(height: 8),
                const _Aviso(texto: 'Falta el documento de respaldo'),
              ],
              if (solicitud.afectaVacaciones &&
                  !(solicitud.saldo?.alcanzaPara(solicitud.diasSolicitados) ??
                      true)) ...[
                const SizedBox(height: 8),
                _Aviso(
                  texto:
                      'Supera su saldo: '
                      '${SaldoVacacion.dias(solicitud.saldo!.diasSaldo!)} días',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip con el nombre del tipo de ausencia. Usa el ámbar de la guía, que
/// significa "pendiente": toda la bandeja lo está.
class ChipTipoAusencia extends StatelessWidget {
  final String nombre;

  const ChipTipoAusencia({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ambar100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        nombre,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.ambar700,
        ),
      ),
    );
  }
}

/// Aviso rojo pequeño dentro de la tarjeta.
class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 15, color: AppColors.rojo700),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12, color: AppColors.rojo700),
          ),
        ),
      ],
    );
  }
}
