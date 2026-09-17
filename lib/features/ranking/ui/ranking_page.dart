import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/ranking/data/ranking_service.dart';
import 'package:mobile_ssas_rrhh/features/ranking/model/candidato_ranking.dart';
import 'package:mobile_ssas_rrhh/features/ranking/ui/widgets/candidato_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Ranking móvil del reclutador (T2-20 · HU-07 · CU-14).
/// Candidatos de una vacante ordenados por afinidad de IA.
///
/// Es SOLO LECTURA: el reclutador consulta desde el móvil, pero mover
/// etapas o editar candidatos se hace desde la web. Por eso no hay onTap
/// en las tarjetas ni acciones en la cabecera.
///
/// Maneja los CUATRO estados de siempre:
///   1. Cargando       -> spinner
///   2. Con datos      -> lista ordenada     (captura "con datos")
///   3. Lista vacía    -> aún no hay postulantes (captura "vacía")
///   4. Error          -> mensaje + reintentar   (captura "con error")
///
/// Ubicación:  lib/features/ranking/ui/ranking_page.dart
class RankingPage extends StatefulWidget {
  final int vacanteId;
  final String vacanteTitulo;
  final RankingService service;

  const RankingPage({
    super.key,
    required this.vacanteId,
    required this.vacanteTitulo,
    required this.service,
  });

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late Future<List<CandidatoRanking>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.porVacante(widget.vacanteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Cabecera(titulo: widget.vacanteTitulo),
          Expanded(
            child: FutureBuilder<List<CandidatoRanking>>(
              future: _futuro,
              builder: (context, snap) {
                // Estado 1: cargando
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.verde600),
                  );
                }
                // Estado 4: error
                if (snap.hasError) {
                  return _EstadoError(
                    mensaje: mensajeDeError(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                final candidatos = snap.data ?? const [];
                // Estado 3: la vacante todavía no tiene postulantes
                if (candidatos.isEmpty) return const _EstadoVacio();
                // Estado 2: con datos
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    // Una fila más: el resumen que va encima de la lista.
                    itemCount: candidatos.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return _Resumen(cantidad: candidatos.length);
                      }
                      return CandidatoCard(candidato: candidatos[i - 1]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía, con el título de la vacante.
class _Cabecera extends StatelessWidget {
  final String titulo;

  const _Cabecera({required this.titulo});

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
                const Text(
                  'Selección · Ranking IA',
                  style: TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
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

/// "6 postulantes · ordenados por afinidad de IA", como la maqueta web,
/// más el aviso de que desde el móvil no se gestiona.
class _Resumen extends StatelessWidget {
  final int cantidad;

  const _Resumen({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final texto = cantidad == 1 ? '1 postulante' : '$cantidad postulantes';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$texto · ordenados por afinidad de IA',
            style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
          ),
          const SizedBox(height: 4),
          const Text(
            'Solo lectura · las etapas se mueven desde la web.',
            style: TextStyle(fontSize: 11.5, color: AppColors.tinta2),
          ),
        ],
      ),
    );
  }
}

/// Estado 3: la vacante existe pero nadie ha postulado todavía.
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.tinta2),
            SizedBox(height: 12),
            Text(
              'Esta vacante todavía no tiene postulantes',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado 4: no se pudo cargar.
class _EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _EstadoError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.rojo100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off,
                color: AppColors.rojo700,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.tinta2, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
