import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/seguimiento/model/etapa_postulacion.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Línea de tiempo vertical de la postulación (T2-18).
///
/// Traduce a Flutter el CSS de la guía del equipo:
///   .linea-t  -> raya vertical de 2.5 px en AppColors.verde600
///   .hito     -> punto de 9 px en verde600 + título y detalle
///   .hito.fut -> punto en AppColors.verde300 y texto en AppColors.tinta2
///
/// Ubicación:  lib/features/seguimiento/ui/widgets/linea_tiempo.dart
class LineaTiempo extends StatelessWidget {
  final List<EtapaPostulacion> etapas;

  const LineaTiempo({super.key, required this.etapas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < etapas.length; i++)
          _Hito(etapa: etapas[i], esUltimo: i == etapas.length - 1),
      ],
    );
  }
}

// Medidas de la guía, en un solo sitio para no repetir números sueltos.
const double _anchoCanal = 24; // columna donde va la raya y el punto
const double _centro = 12; // eje de la raya dentro del canal
const double _grosorRaya = 2.5;
const double _diametroPunto = 9;
const double _puntoArriba = 5; // alinea el punto con la primera línea de texto
const double _separacionHitos = 18;

/// Una fila de la línea de tiempo: el canal con la raya y el punto a la
/// izquierda, y el texto del hito a la derecha.
class _Hito extends StatelessWidget {
  final EtapaPostulacion etapa;
  final bool esUltimo;

  const _Hito({required this.etapa, required this.esUltimo});

  @override
  Widget build(BuildContext context) {
    final alcanzada = etapa.alcanzada;

    // IntrinsicHeight hace que el canal de la izquierda crezca hasta la
    // altura del texto de la derecha, para que la raya quede continua.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _anchoCanal,
            child: _Canal(alcanzada: alcanzada, esUltimo: esUltimo),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : _separacionHitos),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etapa.nombre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      // Hito alcanzado: texto normal. Futuro: atenuado.
                      color: alcanzada ? AppColors.tinta : AppColors.tinta2,
                    ),
                  ),
                  if (etapa.subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      etapa.subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.tinta2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La raya vertical y el punto del hito.
class _Canal extends StatelessWidget {
  final bool alcanzada;
  final bool esUltimo;

  const _Canal({required this.alcanzada, required this.esUltimo});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // La raya baja hasta el final del hito, salvo en el último, donde
        // se corta en el centro del punto para no dejar un cabo suelto.
        Positioned(
          left: _centro - _grosorRaya / 2,
          top: 0,
          bottom: esUltimo ? null : 0,
          height: esUltimo ? _puntoArriba + _diametroPunto / 2 : null,
          width: _grosorRaya,
          child: const ColoredBox(color: AppColors.verde600),
        ),
        Positioned(
          left: _centro - _diametroPunto / 2,
          top: _puntoArriba,
          child: Container(
            width: _diametroPunto,
            height: _diametroPunto,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: alcanzada ? AppColors.verde600 : AppColors.verde300,
            ),
          ),
        ),
      ],
    );
  }
}
