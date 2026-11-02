import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Cabecera verde de la guía para las pantallas del administrador:
/// "Administración / Tipos de ausencia", "Tipos de ausencia / Editar tipo".
class CabeceraAdmin extends StatelessWidget {
  final String etiqueta;
  final String titulo;

  const CabeceraAdmin({
    super.key,
    required this.etiqueta,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.verde950,
      padding: const EdgeInsets.fromLTRB(8, 44, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    color: Color(0xFF8FB49C),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
