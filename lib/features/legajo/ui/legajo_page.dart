import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service.dart';
import 'package:mobile_ssas_rrhh/features/legajo/model/documento_empleado.dart';
import 'package:mobile_ssas_rrhh/features/legajo/ui/widgets/documento_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Mi legajo digital (T3-27 · HU-12 · CU-20).
/// El colaborador consulta sus documentos personales con su tipo, fecha de
/// emisión y de vencimiento, y la app le avisa de los que están por vencer.
///
/// Es SOLO LECTURA: los documentos los carga RR. HH. desde la web (T3-02).
///
/// Maneja los CUATRO estados de siempre:
///   1. Cargando    -> spinner
///   2. Con datos   -> aviso + lista ordenada por urgencia (captura "con datos")
///   3. Vacío       -> todavía no hay documentos         (captura "vacía")
///   4. Error       -> mensaje + reintentar               (captura "con error")
///
/// Ubicación:  lib/features/legajo/ui/legajo_page.dart
class LegajoPage extends StatefulWidget {
  final LegajoService service;

  /// De dónde sale "hoy" para calcular la vigencia. Las pruebas lo fijan;
  /// en la app es el reloj del teléfono.
  final DateTime Function() hoy;

  /// Cómo se abre el archivo de un documento. Por defecto, en el visor del
  /// sistema; las pruebas lo cambian para no lanzar nada de verdad.
  final Future<bool> Function(Uri archivo) abrirArchivo;

  const LegajoPage({
    super.key,
    required this.service,
    this.hoy = DateTime.now,
    this.abrirArchivo = _abrirFuera,
  });

  static Future<bool> _abrirFuera(Uri archivo) =>
      launchUrl(archivo, mode: LaunchMode.externalApplication);

  @override
  State<LegajoPage> createState() => _LegajoPageState();
}

class _LegajoPageState extends State<LegajoPage> {
  late Future<List<DocumentoEmpleado>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.mios();
    });
  }

  Future<void> _verArchivo(String url) async {
    final uri = Uri.tryParse(url);
    final abierto = uri != null && await widget.abrirArchivo(uri);
    if (abierto || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el archivo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: FutureBuilder<List<DocumentoEmpleado>>(
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
                    mensaje: mensajeDeErrorLegajo(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                final recibidos = snap.data ?? const [];
                // Estado 3: RR. HH. todavía no cargó ningún documento
                if (recibidos.isEmpty) return const _EstadoVacio();

                // Estado 2: con datos. Se ordena aquí y no en el servicio
                // para que la pantalla cumpla su promesa con cualquier
                // backend: lo urgente siempre arriba.
                final hoy = widget.hoy();
                final documentos = [...recibidos]
                  ..sort(DocumentoEmpleado.porUrgencia(hoy));

                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    // Una fila más: el aviso que va encima de la lista.
                    itemCount: documentos.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return AvisoVencimientos(
                          documentos: documentos,
                          hoy: hoy,
                        );
                      }
                      final doc = documentos[i - 1];
                      final url = doc.archivoUrl;
                      return DocumentoCard(
                        documento: doc,
                        hoy: hoy,
                        onVerArchivo: url == null
                            ? null
                            : () => _verArchivo(url),
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

/// El aviso de la tarea: "avisa de los que están por vencer". Va arriba de
/// la lista para que se vea sin hacer scroll. Si todo está en regla, lo
/// dice en verde en vez de desaparecer.
class AvisoVencimientos extends StatelessWidget {
  final List<DocumentoEmpleado> documentos;
  final DateTime hoy;

  const AvisoVencimientos({
    super.key,
    required this.documentos,
    required this.hoy,
  });

  @override
  Widget build(BuildContext context) {
    final vencidos = documentos
        .where((d) => d.vigencia(hoy) == Vigencia.vencido)
        .length;
    final porVencer = documentos
        .where((d) => d.vigencia(hoy) == Vigencia.porVencer)
        .length;

    final enRegla = vencidos == 0 && porVencer == 0;
    final (fondo, color, icono) = switch ((vencidos, enRegla)) {
      (_, true) => (
        AppColors.verde100,
        AppColors.verde600,
        Icons.verified_outlined,
      ),
      (> 0, _) => (AppColors.rojo100, AppColors.rojo700, Icons.error_outline),
      _ => (AppColors.ambar100, AppColors.ambar700, Icons.schedule_outlined),
    };

    final lineas = enRegla
        ? ['Todos tus documentos están vigentes.']
        : [
            if (vencidos > 0)
              vencidos == 1
                  ? '1 documento vencido'
                  : '$vencidos documentos vencidos',
            if (porVencer > 0)
              porVencer == 1
                  ? '1 documento vence en los próximos '
                        '${DocumentoEmpleado.diasAviso} días'
                  : '$porVencer documentos vencen en los próximos '
                        '${DocumentoEmpleado.diasAviso} días',
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final linea in lineas)
                  Text(
                    linea,
                    style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!enRegla) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Renuévalos y entrégalos a RR. HH. para actualizar tu '
                    'legajo.',
                    style: TextStyle(color: AppColors.tinta2, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía: "Colaborador / Mi legajo digital".
class _Cabecera extends StatelessWidget {
  const _Cabecera();

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Colaborador',
                  style: TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
                ),
                SizedBox(height: 6),
                Text(
                  'Mi legajo digital',
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

/// Estado 3: RR. HH. todavía no cargó documentos de este colaborador.
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
            Icon(Icons.folder_open_outlined, size: 48, color: AppColors.tinta2),
            SizedBox(height: 12),
            Text(
              'Todavía no tienes documentos en tu legajo',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Aparecerán aquí cuando RR. HH. los cargue.',
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
