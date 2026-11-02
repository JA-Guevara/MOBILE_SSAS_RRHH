import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/widgets/condiciones_tipo.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/model/reglas_tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/ui/editar_tipo_ausencia_page.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/ui/widgets/cabecera_admin.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Configurar los tipos de ausencia desde el móvil (T3-30). Versión
/// reducida de la pantalla web: el administrador ve cada tipo con sus
/// condiciones y su tope anual, y toca uno para editarlo.
///
/// Estados para la evidencia:
///   1. Cargando        -> spinner
///   2. Con tipos       -> captura "con datos" (los inactivos, al final)
///   3. Sin tipos       -> mensaje (captura "vacía")
///   4. Error           -> mensaje + reintentar ("error", "sesión" y
///                         "no es administrador")
///   El formulario de edición tiene sus propios estados: ver
///   EditarTipoAusenciaPage.
///
/// Ubicación:  lib/features/tipos_ausencia/ui/tipos_ausencia_page.dart
class TiposAusenciaPage extends StatefulWidget {
  final TiposAusenciaService service;

  const TiposAusenciaPage({super.key, required this.service});

  @override
  State<TiposAusenciaPage> createState() => _TiposAusenciaPageState();
}

class _TiposAusenciaPageState extends State<TiposAusenciaPage> {
  late Future<List<TipoAusencia>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.listar();
    });
  }

  Future<void> _editar(TipoAusencia tipo, List<TipoAusencia> todos) async {
    final guardado = await Navigator.of(context).push<TipoAusencia>(
      MaterialPageRoute(
        builder: (_) => EditarTipoAusenciaPage(
          service: widget.service,
          tipo: tipo,
          // Para avisar antes de guardar si el código ya lo usa otro tipo.
          codigosDeOtros: [
            for (final t in todos)
              if (t.id != tipo.id && t.codigo != null) t.codigo!,
          ],
        ),
      ),
    );
    if (guardado == null || !mounted) return;

    // Se vuelve a pedir la lista: así se ve lo que quedó en el backend.
    _cargar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Se guardaron los cambios de "${guardado.nombre}".'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CabeceraAdmin(
            etiqueta: 'Administración',
            titulo: 'Tipos de ausencia',
          ),
          Expanded(
            child: FutureBuilder<List<TipoAusencia>>(
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
                    mensaje: mensajeDeErrorTiposAusencia(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                final tipos = snap.data!;
                // Estado 3: sin tipos
                if (tipos.isEmpty) return const _EstadoVacio();
                // Estado 2: con tipos
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: _Lista(
                    tipos: tipos,
                    onEditar: (t) => _editar(t, tipos),
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

class _Lista extends StatelessWidget {
  final List<TipoAusencia> tipos;
  final ValueChanged<TipoAusencia> onEditar;

  const _Lista({required this.tipos, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    final activos = tipos.where((t) => t.activo).length;
    final resumen = [
      tipos.length == 1 ? '1 tipo' : '${tipos.length} tipos',
      activos == 1 ? '1 activo' : '$activos activos',
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          resumen,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.tinta2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Toca un tipo para editar sus condiciones y su tope anual.',
          style: TextStyle(fontSize: 12.5, color: AppColors.tinta2),
        ),
        const SizedBox(height: 12),
        for (final t in tipos) _TarjetaTipo(tipo: t, onTap: () => onEditar(t)),
        const SizedBox(height: 8),
        const Text(
          'Para dejar de usar un tipo, desactívalo: los colaboradores ya no '
          'podrán elegirlo al pedir una ausencia.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.tinta2),
        ),
      ],
    );
  }
}

/// Un tipo de ausencia: nombre, código y sus condiciones en chips.
class _TarjetaTipo extends StatelessWidget {
  final TipoAusencia tipo;
  final VoidCallback onTap;

  const _TarjetaTipo({required this.tipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tipo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: t.activo ? AppColors.carta : AppColors.mentaBg,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.tarjeta),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.tarjeta),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.nombre,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: t.activo
                                    ? AppColors.tinta
                                    : AppColors.tinta2,
                              ),
                            ),
                          ),
                          if (t.codigo != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              t.codigo!,
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 0.5,
                                color: AppColors.tinta2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children: _chips(t)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.tinta2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Las condiciones que el administrador configura, con los mismos chips
  /// que ve el colaborador al pedir la ausencia.
  static List<Widget> _chips(TipoAusencia t) => [
    if (!t.activo)
      const ChipCondicion(
        texto: 'Inactivo',
        fondo: AppColors.rojo100,
        color: AppColors.rojo700,
      ),
    ChipCondicion(
      texto: ReglasTipoAusencia.textoTope(t.diasMaximosAnio),
      fondo: AppColors.azul100,
      color: AppColors.azul700,
    ),
    ChipCondicion(
      texto: t.esRemunerado ? 'Con goce de haber' : 'Sin goce de haber',
      fondo: t.esRemunerado ? AppColors.verde100 : AppColors.ambar100,
      color: t.esRemunerado ? AppColors.verde600 : AppColors.ambar700,
    ),
    if (t.descuentaVacacion)
      const ChipCondicion(
        texto: 'Descuenta vacación',
        fondo: AppColors.verde100,
        color: AppColors.verde600,
      ),
    if (t.requiereDocumento)
      const ChipCondicion(
        texto: 'Requiere documento',
        fondo: AppColors.ambar100,
        color: AppColors.ambar700,
      ),
    if (!t.requiereAprobacion)
      const ChipCondicion(
        texto: 'Sin aprobación del jefe',
        fondo: AppColors.lila100,
        color: AppColors.lila700,
      ),
  ];
}

/// Estado 3: la empresa todavía no configuró ningún tipo.
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
            Icon(Icons.event_busy_outlined, size: 48, color: AppColors.tinta2),
            SizedBox(height: 12),
            Text(
              'Tu empresa todavía no tiene tipos de ausencia',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando se registren, podrás editarlos aquí.',
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
