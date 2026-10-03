import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/ranking/model/candidato_ranking.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/model/etapa_postulacion.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Tarjeta de un candidato en el ranking (T2-20).
///
/// No lleva onTap: la pantalla es SOLO LECTURA. Mover etapas o editar al
/// candidato se hace desde la web, así que la tarjeta no invita a tocarla.
///
/// Ubicación:  lib/features/ranking/ui/widgets/candidato_card.dart
class CandidatoCard extends StatelessWidget {
  final CandidatoRanking candidato;

  const CandidatoCard({super.key, required this.candidato});

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
                    candidato.nombreCompleto,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 17,
                      color: AppColors.tinta,
                    ),
                  ),
                  if (candidato.subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      candidato.subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.tinta2,
                      ),
                    ),
                  ],
                  if (candidato.etapa != null) ...[
                    const SizedBox(height: 10),
                    ChipEtapa(etapa: candidato.etapa!),
                  ],
                ],
              ),
            ),
            // La insignia de afinidad solo aparece cuando la IA puntuó.
            if (candidato.tieneAfinidad) ...[
              const SizedBox(width: 10),
              ChipAfinidad(texto: candidato.afinidadTexto),
            ],
          ],
        ),
      ),
    );
  }
}

/// Insignia lila de IA: la clase .afin / .c-ia de la guía.
class ChipAfinidad extends StatelessWidget {
  final String texto;

  const ChipAfinidad({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lila100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.lila700,
        ),
      ),
    );
  }
}

/// Chip de la etapa actual: la clase .chip de la guía.
///
/// El color sale de etapa_reclutamiento.color, que es el campo que cada
/// empresa configura para sus etapas. Solo si ese campo viene nulo o con un
/// valor que no se puede leer, se cae a los tokens de AppColors.
class ChipEtapa extends StatelessWidget {
  final EtapaPostulacion etapa;

  const ChipEtapa({super.key, required this.etapa});

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = _colores(etapa);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etapa.nombre,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: texto,
        ),
      ),
    );
  }

  /// Fondo y texto del chip. El backend manda UN color; la guía dibuja los
  /// chips con fondo claro y texto oscuro, así que ese color se usa para el
  /// texto y una versión translúcida suya para el fondo.
  static (Color, Color) _colores(EtapaPostulacion etapa) {
    final configurado = parseColorEtapa(etapa.color);
    if (configurado == null) return _coloresDeToken(etapa);

    // Un color muy claro sería ilegible como texto sobre un fondo claro:
    // en ese caso se oscurece manteniendo el tono que eligió la empresa.
    final texto = configurado.computeLuminance() > 0.45
        ? HSLColor.fromColor(configurado).withLightness(0.32).toColor()
        : configurado;

    return (configurado.withValues(alpha: 0.15), texto);
  }

  /// Respaldo cuando la empresa no configuró color: .c-ok / .c-warn /
  /// .c-info / rojo, según lo que significa la etapa.
  static (Color, Color) _coloresDeToken(EtapaPostulacion etapa) {
    if (etapa.esContratado) return (AppColors.verde100, AppColors.verde600);
    if (etapa.esRechazado) return (AppColors.rojo100, AppColors.rojo700);
    if (etapa.esInicial) return (AppColors.azul100, AppColors.azul700);
    return (AppColors.ambar100, AppColors.ambar700);
  }
}

/// Lee etapa_reclutamiento.color y lo convierte en un Color.
///
/// >>> VERIFICA contra /docs <<<  Se asume una cadena hexadecimal, con o sin
/// almohadilla, de 6 dígitos (RRGGBB) u 8 (AARRGGBB). Si el backend guarda
/// nombres de color ("rojo") o un formato distinto, esta función es lo único
/// que hay que cambiar.
///
/// Devuelve null si el campo viene vacío o no se puede leer, para que quien
/// llama pueda caer a los tokens.
Color? parseColorEtapa(String? valor) {
  if (valor == null) return null;

  var hex = valor.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex'; // sin canal alfa: se asume opaco
  if (hex.length != 8) return null;

  final entero = int.tryParse(hex, radix: 16);
  if (entero == null) return null;

  return Color(entero);
}
