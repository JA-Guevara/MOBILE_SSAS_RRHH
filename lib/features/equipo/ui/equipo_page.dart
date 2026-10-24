import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/miembro_equipo.dart';
import 'package:mobile_ssas_rrhh/features/equipo/ui/widgets/miembro_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Equipo a mi cargo (T3-29 · HU-12 · CU-20).
/// El jefe directo ve a las personas que le reportan, con su cargo y su
/// estado de asistencia del día.
///
/// Es SOLO LECTURA: la gestión vive en la web. Por eso no hay onTap en las
/// tarjetas ni acciones en la cabecera, igual que el ranking de T2-20.
///
/// Maneja los CUATRO estados de siempre:
///   1. Cargando    -> spinner
///   2. Con datos   -> resumen del día + lista  (captura "con datos")
///   3. Vacío       -> nadie le reporta todavía (captura "vacía")
///   4. Error       -> mensaje + reintentar     (captura "con error")
///
/// Ubicación:  lib/features/equipo/ui/equipo_page.dart
class EquipoPage extends StatefulWidget {
  final EquipoService service;

  const EquipoPage({super.key, required this.service});

  @override
  State<EquipoPage> createState() => _EquipoPageState();
}

class _EquipoPageState extends State<EquipoPage> {
  late Future<List<MiembroEquipo>> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.miEquipo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: FutureBuilder<List<MiembroEquipo>>(
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
                    mensaje: mensajeDeErrorEquipo(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                final equipo = snap.data ?? const [];
                // Estado 3: nadie le reporta a este jefe todavía
                if (equipo.isEmpty) return const _EstadoVacio();
                // Estado 2: con datos
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    // Una fila más: el resumen que va encima de la lista.
                    itemCount: equipo.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) return ResumenEquipo(equipo: equipo);
                      return MiembroCard(miembro: equipo[i - 1]);
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

/// "6 personas a tu cargo" y cuántas hay en cada estado hoy, más el aviso
/// de que desde el móvil no se gestiona.
class ResumenEquipo extends StatelessWidget {
  final List<MiembroEquipo> equipo;

  const ResumenEquipo({super.key, required this.equipo});

  /// "3 en jornada · 1 salió · 1 sin marcar · 1 ausente". Omite los
  /// estados sin nadie.
  static String conteo(List<MiembroEquipo> equipo) {
    final partes = <String>[];
    for (final estado in EstadoDia.values) {
      final n = equipo.where((m) => m.estadoDia == estado).length;
      if (n > 0) {
        partes.add('$n ${ChipEstadoDia.etiqueta(estado).toLowerCase()}');
      }
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final total = equipo.length == 1
        ? '1 persona a tu cargo'
        : '${equipo.length} personas a tu cargo';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total,
            style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
          ),
          const SizedBox(height: 4),
          Text(
            'Hoy: ${conteo(equipo)}',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.tinta,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Solo lectura · la gestión del equipo vive en la web.',
            style: TextStyle(fontSize: 11.5, color: AppColors.tinta2),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía: "Jefe directo / Equipo a mi cargo".
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
                  'Jefe directo',
                  style: TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
                ),
                SizedBox(height: 6),
                Text(
                  'Equipo a mi cargo',
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

/// Estado 3: nadie tiene a este jefe como jefe_directo en un contrato
/// vigente.
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
            Icon(Icons.groups_outlined, size: 48, color: AppColors.tinta2),
            SizedBox(height: 12),
            Text(
              'Todavía no tienes personas a tu cargo',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Aparecerán aquí cuando RR. HH. te asigne como jefe directo '
              'en sus contratos.',
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
