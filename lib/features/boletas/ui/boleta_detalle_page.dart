import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_pago.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/widgets/boleta_card.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/widgets/seccion_detalle.dart';
import 'package:mobile_ssas_rrhh/shared/format/moneda.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Detalle de una boleta (T3-20), segunda pantalla: haberes, descuentos y
/// el líquido pagable.
///
/// Maneja los CUATRO estados de siempre:
///   1. Cargando   -> spinner
///   2. Con datos  -> haberes y descuentos  (captura "con datos")
///   3. Vacío      -> la boleta no trae líneas (captura "vacía")
///   4. Error      -> mensaje + reintentar    (captura "con error")
///
/// Ubicación:  lib/features/boletas/ui/boleta_detalle_page.dart
class BoletaDetallePage extends StatefulWidget {
  final String boletaId;

  /// Se recibe de la lista para poder pintar la cabecera desde el primer
  /// frame, sin esperar a que llegue el detalle.
  final String etiquetaPeriodo;

  final BoletasService service;

  const BoletaDetallePage({
    super.key,
    required this.boletaId,
    required this.etiquetaPeriodo,
    required this.service,
  });

  @override
  State<BoletaDetallePage> createState() => _BoletaDetallePageState();
}

class _BoletaDetallePageState extends State<BoletaDetallePage> {
  late Future<BoletaPago> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.detalle(widget.boletaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Cabecera(titulo: widget.etiquetaPeriodo),
          Expanded(
            child: FutureBuilder<BoletaPago>(
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
                final boleta = snap.data;
                if (boleta == null) {
                  return _EstadoError(
                    mensaje: mensajeDeErrorBoletas(Object()),
                    onReintentar: _cargar,
                  );
                }
                // Estado 3: la boleta existe pero no trae líneas
                if (boleta.detalles.isEmpty) {
                  return _EstadoVacio(boleta: boleta);
                }
                // Estado 2: con datos
                return _Contenido(boleta: boleta);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía, con el periodo y el botón de volver.
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
                  'Boleta de pago',
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

/// Estado 2: la boleta entera.
class _Contenido extends StatelessWidget {
  final BoletaPago boleta;

  const _Contenido({required this.boleta});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Resumen(boleta: boleta),
        const SizedBox(height: 12),
        SeccionDetalle(
          titulo: 'Haberes',
          lineas: boleta.haberes,
          total: boleta.totalGanado,
          color: AppColors.tinta,
        ),
        SeccionDetalle(
          titulo: 'Descuentos',
          lineas: boleta.descuentos,
          total: boleta.totalDescuentos,
          color: AppColors.rojo700,
        ),
        // Líneas con un "tipo" que no supimos clasificar. Se muestran para
        // no perderlas; si este bloque aparece, hay que revisar los
        // literales del backend contra BoletaDetalle.parseTipo.
        if (boleta.otras.isNotEmpty)
          SeccionDetalle(
            titulo: 'Otros conceptos',
            lineas: boleta.otras,
            total: boleta.totalAportesPatronales,
            color: AppColors.tinta2,
          ),
        const SizedBox(height: 4),
        LiquidoPagable(monto: boleta.liquidoPagable),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Cabecera de datos de la boleta: número, estado, días y salario básico.
class _Resumen extends StatelessWidget {
  final BoletaPago boleta;

  const _Resumen({required this.boleta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carta,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        border: Border.all(color: AppColors.borde),
      ),
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
                    if (boleta.numero != null)
                      Text(
                        boleta.numero!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.tinta,
                        ),
                      ),
                    if (boleta.resumenDias.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        boleta.resumenDias,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.tinta2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (boleta.estado != null)
                ChipEstadoBoleta(estado: boleta.estado!),
            ],
          ),
          if (boleta.salarioBasico != null) ...[
            const Divider(height: 22, color: AppColors.borde),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Salario básico',
                    style: TextStyle(fontSize: 13, color: AppColors.tinta2),
                  ),
                ),
                Text(
                  Moneda.bs(boleta.salarioBasico),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tinta,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Estado 3: la boleta llegó sin líneas. Se muestra igual el líquido, que
/// es el dato que el colaborador vino a buscar.
class _EstadoVacio extends StatelessWidget {
  final BoletaPago boleta;

  const _EstadoVacio({required this.boleta});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Resumen(boleta: boleta),
        const SizedBox(height: 24),
        const Icon(
          Icons.receipt_long_outlined,
          size: 40,
          color: AppColors.tinta2,
        ),
        const SizedBox(height: 10),
        const Text(
          'Esta boleta no tiene el desglose de haberes y descuentos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.tinta2, fontSize: 14),
        ),
        const SizedBox(height: 24),
        LiquidoPagable(monto: boleta.liquidoPagable),
      ],
    );
  }
}

/// Estado 4: no se pudo cargar el detalle.
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
