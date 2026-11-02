import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/legajo/model/documento_empleado.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Tarjeta de un documento del legajo: tipo, nombre, fechas y el chip de
/// vigencia. Si tiene archivo, ofrece abrirlo.
///
/// Ubicación:  lib/features/legajo/ui/widgets/documento_card.dart
class DocumentoCard extends StatelessWidget {
  final DocumentoEmpleado documento;

  /// Fecha contra la que se calcula la vigencia. Se recibe en vez de leer
  /// DateTime.now() aquí para que las pruebas puedan fijar el día.
  final DateTime hoy;

  /// Null si el documento no tiene archivo: entonces no hay botón.
  final VoidCallback? onVerArchivo;

  const DocumentoCard({
    super.key,
    required this.documento,
    required this.hoy,
    this.onVerArchivo,
  });

  @override
  Widget build(BuildContext context) {
    final vigencia = documento.vigencia(hoy);
    final aviso = documento.avisoVencimiento(hoy);

    return Card(
      color: AppColors.carta,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        side: const BorderSide(color: AppColors.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    documento.tipoEtiqueta.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: AppColors.tinta2,
                    ),
                  ),
                ),
                ChipVigencia(vigencia: vigencia),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              documento.nombre,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 17,
                color: AppColors.tinta,
              ),
            ),
            const SizedBox(height: 10),
            _Fechas(documento: documento),
            if (aviso.isNotEmpty &&
                (vigencia == Vigencia.vencido ||
                    vigencia == Vigencia.porVencer)) ...[
              const SizedBox(height: 8),
              Text(
                aviso,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: vigencia == Vigencia.vencido
                      ? AppColors.rojo700
                      : AppColors.ambar700,
                ),
              ),
            ],
            if (onVerArchivo != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onVerArchivo,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.verde600,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Ver archivo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Emitido 13/12/2019 · Vence 05/11/2026", u "Sin vencimiento".
class _Fechas extends StatelessWidget {
  final DocumentoEmpleado documento;

  const _Fechas({required this.documento});

  @override
  Widget build(BuildContext context) {
    final emision = documento.emisionCorta;
    final vence = documento.vencimientoCorto;
    final partes = [
      if (emision.isNotEmpty) 'Emitido $emision',
      vence.isEmpty ? 'Sin vencimiento' : 'Vence $vence',
    ];

    return Text(
      partes.join(' · '),
      style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
    );
  }
}

/// Chip de vigencia con los colores de la guía: rojo vencido, ámbar por
/// vencer, verde vigente y azul (informativo) cuando no vence.
class ChipVigencia extends StatelessWidget {
  final Vigencia vigencia;

  const ChipVigencia({super.key, required this.vigencia});

  @override
  Widget build(BuildContext context) {
    final (fondo, texto, etiqueta) = switch (vigencia) {
      Vigencia.vencido => (AppColors.rojo100, AppColors.rojo700, 'Vencido'),
      Vigencia.porVencer => (
        AppColors.ambar100,
        AppColors.ambar700,
        'Por vencer',
      ),
      Vigencia.vigente => (AppColors.verde100, AppColors.verde600, 'Vigente'),
      Vigencia.sinVencimiento => (
        AppColors.azul100,
        AppColors.azul700,
        'No vence',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: texto,
        ),
      ),
    );
  }
}
