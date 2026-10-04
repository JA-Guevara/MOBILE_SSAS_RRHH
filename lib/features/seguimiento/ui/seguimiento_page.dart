import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/model/seguimiento_postulacion.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/ui/widgets/linea_tiempo.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Línea de tiempo de la postulación (T2-18 · HU-09 · CU-11).
/// Se abre con el código de seguimiento que devolvió T1-20.
///
/// Maneja los CUATRO estados que necesitas para la evidencia, igual que
/// VacantesPublicasPage:
///   1. Cargando                -> spinner
///   2. Con datos               -> línea de tiempo   (captura "con datos")
///   3. Código no encontrado    -> mensaje amable    (captura "vacía")
///   4. Error                   -> mensaje + reintentar (captura "con error")
///
/// Ubicación:  lib/features/seguimiento/ui/seguimiento_page.dart
class SeguimientoPage extends StatefulWidget {
  final String codigo;
  final SeguimientoService service;

  const SeguimientoPage({
    super.key,
    required this.codigo,
    required this.service,
  });

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  late Future<SeguimientoPostulacion?> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.porCodigo(widget.codigo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Cabecera(codigo: widget.codigo),
          Expanded(
            child: FutureBuilder<SeguimientoPostulacion?>(
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
                final postulacion = snap.data;
                // Estado 3: el código no corresponde a ninguna postulación
                if (postulacion == null) {
                  return _EstadoVacio(codigo: widget.codigo);
                }
                // Estado 2: con datos
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: _Contenido(postulacion: postulacion),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía: el código arriba y "Mi postulación" debajo.
class _Cabecera extends StatelessWidget {
  final String codigo;

  const _Cabecera({required this.codigo});

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
                  'Código $codigo',
                  style: const TextStyle(
                    color: Color(0xFF8FB49C),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mi postulación',
                  style: TextStyle(
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

/// Estado 2: título de la vacante, empresa y la línea de tiempo.
class _Contenido extends StatelessWidget {
  final SeguimientoPostulacion postulacion;

  const _Contenido({required this.postulacion});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.carta,
            borderRadius: BorderRadius.circular(AppRadii.tarjeta),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                postulacion.vacanteTitulo,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 17,
                  color: AppColors.tinta,
                ),
              ),
              if (postulacion.subtitulo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  postulacion.subtitulo,
                  style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
                ),
              ],
              const SizedBox(height: 18),
              if (postulacion.etapas.isNotEmpty)
                LineaTiempo(etapas: postulacion.etapas)
              else ...[
                _Dato(etiqueta: 'Estado', valor: postulacion.estado ?? 'Sin información'),
                _Dato(etiqueta: 'Etapa actual', valor: postulacion.etapaActual ?? 'Sin información'),
                if (postulacion.fechaPostulacion != null)
                  _Dato(etiqueta: 'Postulación', valor: _fecha(postulacion.fechaPostulacion!)),
                if (postulacion.fechaUltimoCambio != null)
                  _Dato(etiqueta: 'Último cambio', valor: _fecha(postulacion.fechaUltimoCambio!)),
              ],
            ],
          ),
        ),
        if (postulacion.motivoRechazo != null) ...[
          const SizedBox(height: 12),
          _MotivoRechazo(motivo: postulacion.motivoRechazo!),
        ],
      ],
    );
  }
}

String _fecha(DateTime fecha) => '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.tinta2)),
      Text(valor, style: const TextStyle(fontSize: 16, color: AppColors.tinta)),
    ]),
  );
}

/// Si el proceso terminó en rechazo, el candidato debe ver por qué.
/// No está en la maqueta: ver la lista de supuestos de la tarea.
class _MotivoRechazo extends StatelessWidget {
  final String motivo;

  const _MotivoRechazo({required this.motivo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rojo100,
        borderRadius: BorderRadius.circular(AppRadii.boton),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.rojo700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              motivo,
              style: const TextStyle(fontSize: 12.5, color: AppColors.rojo700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado 3: el código no existe. No es un error: es una respuesta válida.
class _EstadoVacio extends StatelessWidget {
  final String codigo;

  const _EstadoVacio({required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 48,
              color: AppColors.tinta2,
            ),
            const SizedBox(height: 12),
            Text(
              'No encontramos ninguna postulación con el código $codigo',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa que lo hayas escrito tal como aparece en el correo '
              'de confirmación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Probar con otro código'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado 4: no se pudo consultar.
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
