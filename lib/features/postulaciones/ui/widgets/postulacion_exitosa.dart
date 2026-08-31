import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/model/resultado_postulacion.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Pantalla de confirmación: muestra el CÓDIGO DE SEGUIMIENTO que devolvió
/// el backend (ej. TX-8F4K2). Con ese código el candidato consulta su estado
/// desde la web o la app, así que se puede copiar de un toque.
class PostulacionExitosa extends StatelessWidget {
  final ResultadoPostulacion resultado;
  final String vacanteTitulo;
  final VoidCallback onVolver;

  const PostulacionExitosa({
    super.key,
    required this.resultado,
    required this.vacanteTitulo,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final codigo = resultado.codigoSeguimiento;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.carta,
            borderRadius: BorderRadius.circular(AppRadii.tarjeta),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.verde100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.verde600,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Postulación enviada',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  color: AppColors.tinta,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vacanteTitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
              ),
              const SizedBox(height: 18),
              const Text(
                'CÓDIGO DE SEGUIMIENTO',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.6,
                  color: AppColors.tinta2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _Codigo(codigo: codigo),
              const SizedBox(height: 14),
              Text(
                resultado.mensaje ??
                    'Guarda este código: con él puedes consultar el estado '
                        'de tu postulación desde la web o la app.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.tinta2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onVolver,
          child: const Text('Volver a las vacantes'),
        ),
      ],
    );
  }
}

/// El código en grande sobre franja crema, con botón para copiarlo.
class _Codigo extends StatelessWidget {
  final String codigo;

  const _Codigo({required this.codigo});

  @override
  Widget build(BuildContext context) {
    // Si el backend no mandó código, no inventamos uno: se avisa.
    if (codigo.isEmpty) {
      return const Text(
        'El backend no devolvió un código. Revisa tu correo.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.ambar700),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.circular(AppRadii.boton),
        border: Border.all(color: AppColors.ambar100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            codigo,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: AppColors.tinta,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copiar código',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: AppColors.ambar700,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: codigo));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Código copiado')));
            },
          ),
        ],
      ),
    );
  }
}
