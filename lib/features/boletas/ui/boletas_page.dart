import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_pago.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/boleta_detalle_page.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/widgets/boleta_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Mis boletas de pago (T3-20 · HU-14 · CU-27), primera pantalla.
/// Lista las boletas por periodo; al tocar una se abre su detalle.
///
/// Maneja los CUATRO estados de siempre:
///   1. Cargando    -> spinner
///   2. Con datos   -> lista de boletas    (captura "con datos")
///   3. Vacío       -> todavía no hay boletas (captura "vacía")
///   4. Error       -> mensaje + reintentar   (captura "con error")
///
/// Ubicación:  lib/features/boletas/ui/boletas_page.dart
class BoletasPage extends StatefulWidget {
  final BoletasService service;

  const BoletasPage({super.key, required this.service});

  @override
  State<BoletasPage> createState() => _BoletasPageState();
}

class _BoletasPageState extends State<BoletasPage> {
  late Future<List<BoletaPago>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.mias();
    });
  }

  void _abrirDetalle(BoletaPago boleta) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoletaDetallePage(
          boletaId: boleta.id,
          etiquetaPeriodo: boleta.etiquetaPeriodo,
          service: widget.service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: FutureBuilder<List<BoletaPago>>(
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
                    mensaje: mensajeDeErrorBoletas(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                final boletas = snap.data ?? const [];
                // Estado 3: todavía no le generaron ninguna boleta
                if (boletas.isEmpty) return const _EstadoVacio();
                // Estado 2: con datos
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: boletas.length,
                    itemBuilder: (context, i) => BoletaCard(
                      boleta: boletas[i],
                      onTap: () => _abrirDetalle(boletas[i]),
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

/// Cabecera verde de la guía: "Colaborador / Mis boletas".
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
            'Colaborador',
            style: TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
          ),
          SizedBox(height: 6),
          Text(
            'Mis boletas',
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

/// Estado 3: aún no hay boletas generadas para este colaborador.
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
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.tinta2,
            ),
            SizedBox(height: 12),
            Text(
              'Todavía no tienes boletas de pago',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Aparecerán aquí cuando se cierre el periodo de nómina.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 13),
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
