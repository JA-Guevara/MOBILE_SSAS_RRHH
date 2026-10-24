import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/solicitud_detalle_page.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/solicitud_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Bandeja del jefe (T3-22 · HU-17 · CU-25), primera pantalla.
/// Solicitudes de ausencia esperando su respuesta.
///
/// Maneja los CUATRO estados de siempre:
///   1. Cargando   -> spinner
///   2. Con datos  -> lista de pendientes  (captura "con pendientes")
///   3. Vacío      -> nada por responder   (captura "bandeja vacía")
///   4. Error      -> mensaje + reintentar (capturas "error" y "sesión")
///
/// Ubicación:  lib/features/aprobaciones/ui/bandeja_page.dart
class BandejaPage extends StatefulWidget {
  final AprobacionesService service;

  const BandejaPage({super.key, required this.service});

  @override
  State<BandejaPage> createState() => _BandejaPageState();
}

class _BandejaPageState extends State<BandejaPage> {
  late Future<List<SolicitudAusencia>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.pendientes();
    });
  }

  /// Al volver del detalle se recarga: la solicitud puede haberse respondido
  /// y ya no debería seguir en la bandeja.
  Future<void> _abrirDetalle(SolicitudAusencia solicitud) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SolicitudDetallePage(
          solicitudId: solicitud.id,
          solicitante: solicitud.solicitante,
          service: widget.service,
        ),
      ),
    );
    if (!mounted) return;
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: FutureBuilder<List<SolicitudAusencia>>(
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
                    mensaje: mensajeDeErrorAprobaciones(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                final solicitudes = snap.data ?? const [];
                // Estado 3: no hay nada por responder
                if (solicitudes.isEmpty) return const _EstadoVacio();
                // Estado 2: con datos
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: solicitudes.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) return _Resumen(cantidad: solicitudes.length);
                      final solicitud = solicitudes[i - 1];
                      return SolicitudCard(
                        solicitud: solicitud,
                        onTap: () => _abrirDetalle(solicitud),
                      );
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

/// Cabecera verde de la guía: "Jefatura / Por aprobar".
class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.verde950,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jefatura',
            style: TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
          ),
          SizedBox(height: 6),
          Text(
            'Por aprobar',
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

/// "3 solicitudes · las más antiguas primero".
class _Resumen extends StatelessWidget {
  final int cantidad;

  const _Resumen({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final texto = cantidad == 1 ? '1 solicitud' : '$cantidad solicitudes';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        '$texto · las que llevan más tiempo esperando, primero',
        style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
      ),
    );
  }
}

/// Estado 3: bandeja vacía. Es una buena noticia, no un error.
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
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.verde600,
            ),
            SizedBox(height: 12),
            Text(
              'No tienes solicitudes por responder',
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
