import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/postulacion_page.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/model/vacante.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/ui/widgets/vacante_card.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service.dart';

/// Pantalla del portal público de empleos (T1-18).
/// Muestra las vacantes de una empresa identificada por su slug.
///
/// Maneja los CUATRO estados que necesitas para la evidencia:
///   1. Cargando        -> spinner
///   2. Con datos       -> lista de tarjetas   (captura "con datos")
///   3. Lista vacía     -> mensaje amable        (captura "vacía")
///   4. Error           -> mensaje + reintentar  (captura "con error")
///
/// Ubicación sugerida:  lib/features/vacantes/ui/vacantes_publicas_page.dart
class VacantesPublicasPage extends StatefulWidget {
  final String slug;
  final String empresaNombre;
  final VacantesService service;

  /// Servicio de la pantalla de postulación (T1-20). Si es null, tocar una
  /// tarjeta no hace nada: útil para capturar solo esta pantalla.
  final PostulacionesService? postulacionesService;

  const VacantesPublicasPage({
    super.key,
    required this.slug,
    required this.empresaNombre,
    required this.service,
    this.postulacionesService,
  });

  @override
  State<VacantesPublicasPage> createState() => _VacantesPublicasPageState();
}

class _VacantesPublicasPageState extends State<VacantesPublicasPage> {
  late Future<List<Vacante>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.vacantesPublicas(widget.slug);
    });
  }

  /// T1-20: abre el formulario de postulación de la vacante tocada.
  void _abrirPostulacion(Vacante vacante) {
    final servicio = widget.postulacionesService;
    if (servicio == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostulacionPage(
          slug: widget.slug,
          empresaNombre: widget.empresaNombre,
          vacanteId: vacante.id,
          vacanteTitulo: vacante.titulo,
          service: servicio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Cabecera(empresaNombre: widget.empresaNombre),
          Expanded(
            child: FutureBuilder<List<Vacante>>(
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
                    mensaje: snap.error.toString(),
                    onReintentar: _cargar,
                  );
                }
                final vacantes = snap.data ?? const [];
                // Estado 3: lista vacía
                if (vacantes.isEmpty) {
                  return const _EstadoVacio();
                }
                // Estado 2: con datos
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vacantes.length,
                    itemBuilder: (context, i) => VacanteCard(
                      vacante: vacantes[i],
                      onTap: () => _abrirPostulacion(vacantes[i]),
                    ),
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

class _Cabecera extends StatelessWidget {
  final String empresaNombre;
  const _Cabecera({required this.empresaNombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.verde950,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SSAH · $empresaNombre',
            style: const TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Portal de empleos',
            style: TextStyle(
              fontFamily: 'serif',
              color: Colors.white,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

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
            Icon(Icons.work_outline, size: 48, color: AppColors.tinta2),
            SizedBox(height: 12),
            Text(
              'No hay vacantes publicadas por ahora',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

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
