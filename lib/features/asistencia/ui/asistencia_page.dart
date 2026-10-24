import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/ubicacion_service.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/ui/widgets/boton_marcar.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/ui/widgets/resumen_dia.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Marcación de asistencia con GPS (T3-18 · HU-15 · CU-23).
///
/// Maneja los CUATRO estados de siempre:
///   1. Cargando     -> spinner mientras se consulta el día
///   2. Con datos    -> ya marcó algo hoy      (capturas "con entrada" y
///                      "día completo")
///   3. Vacío        -> todavía no marcó nada  (captura "—:— a —:—")
///   4. Error        -> mensaje + reintentar   (captura "con error")
///
/// Y encima, los tres casos del permiso de ubicación: concedido, denegado
/// (se puede volver a pedir) y denegado permanentemente (hay que ir a los
/// ajustes del teléfono).
///
/// Ubicación:  lib/features/asistencia/ui/asistencia_page.dart
class AsistenciaPage extends StatefulWidget {
  final AsistenciaService service;

  /// Se inyecta para que las capturas y los tests no dependan del GPS real.
  final UbicacionService ubicacion;

  const AsistenciaPage({
    super.key,
    required this.service,
    this.ubicacion = const UbicacionService(),
  });

  @override
  State<AsistenciaPage> createState() => _AsistenciaPageState();
}

class _AsistenciaPageState extends State<AsistenciaPage> {
  /// Estado de la consulta del día.
  var _cargando = true;
  String? _errorCarga;
  Asistencia? _asistencia;

  /// Estado de la marcación en curso.
  var _marcando = false;

  /// Aviso que sale bajo el botón: permiso denegado, GPS apagado, fallo al
  /// registrar, o la confirmación de que la marca quedó grabada.
  _Aviso? _aviso;

  @override
  void initState() {
    super.initState();
    _cargarDia();
  }

  Future<void> _cargarDia() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
      _aviso = null;
    });

    try {
      final marca = await widget.service.deHoy();
      if (!mounted) return;
      setState(() {
        _asistencia = marca;
        _cargando = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = mensajeDeErrorAsistencia(e);
        _cargando = false;
      });
    }
  }

  /// Pide la ubicación y, si la consigue, registra la marca que toque.
  Future<void> _marcar() async {
    final pendiente = _asistencia?.pendiente ?? MarcaPendiente.entrada;
    if (pendiente == MarcaPendiente.ninguna) return;

    setState(() {
      _marcando = true;
      _aviso = null;
    });

    final resultado = await widget.ubicacion.actual();
    if (!mounted) return;

    // Los tres casos del permiso, más el GPS apagado y el fallo de lectura.
    switch (resultado) {
      case UbicacionDenegada(permanente: final permanente):
        setState(() {
          _marcando = false;
          _aviso = permanente
              ? const _Aviso(
                  texto:
                      'Diste permiso de ubicación en "Nunca". Para marcar '
                      'tu asistencia tienes que activarlo desde los ajustes '
                      'del teléfono.',
                  accion: _AccionAviso.abrirAjustes,
                )
              : const _Aviso(
                  texto:
                      'Necesitamos tu ubicación para registrar dónde marcas. '
                      'Sin ese permiso no se puede guardar la marca.',
                  accion: _AccionAviso.reintentarPermiso,
                );
        });
        return;

      case UbicacionSinServicio():
        setState(() {
          _marcando = false;
          _aviso = const _Aviso(
            texto:
                'El GPS de tu teléfono está apagado. Enciéndelo para poder '
                'marcar tu asistencia.',
            accion: _AccionAviso.abrirAjustesUbicacion,
          );
        });
        return;

      case UbicacionFallida(mensaje: final mensaje):
        setState(() {
          _marcando = false;
          _aviso = _Aviso(texto: mensaje, accion: _AccionAviso.reintentar);
        });
        return;

      case UbicacionObtenida(latitud: final lat, longitud: final lon):
        await _registrar(pendiente, lat, lon);
    }
  }

  Future<void> _registrar(
    MarcaPendiente pendiente,
    double latitud,
    double longitud,
  ) async {
    try {
      final marca = pendiente == MarcaPendiente.entrada
          ? await widget.service.marcarEntrada(
              latitud: latitud,
              longitud: longitud,
            )
          : await widget.service.marcarSalida(
              latitud: latitud,
              longitud: longitud,
            );

      if (!mounted) return;
      setState(() {
        _asistencia = marca;
        _marcando = false;
        _aviso = _Aviso(
          texto: pendiente == MarcaPendiente.entrada
              ? 'Entrada registrada a las ${marca.entradaCorta}.'
              : 'Salida registrada a las ${marca.salidaCorta}.',
          accion: _AccionAviso.ninguna,
          exito: true,
        );
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _marcando = false;
        _aviso = _Aviso(
          texto: mensajeDeErrorAsistencia(e),
          accion: _AccionAviso.reintentar,
        );
      });
      // Si el backend rechazó por "una marca por día", el día real puede ser
      // distinto del que tenemos: se vuelve a consultar para no mentir.
      await _cargarDia();
    }
  }

  Future<void> _ejecutar(_AccionAviso accion) async {
    switch (accion) {
      case _AccionAviso.abrirAjustes:
        await widget.ubicacion.abrirAjustes();
      case _AccionAviso.abrirAjustesUbicacion:
        await widget.ubicacion.abrirAjustesUbicacion();
      case _AccionAviso.reintentarPermiso:
      case _AccionAviso.reintentar:
        await _marcar();
      case _AccionAviso.ninguna:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(child: _cuerpo()),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    // Estado 1: cargando
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verde600),
      );
    }
    // Estado 4: no se pudo consultar el día
    final error = _errorCarga;
    if (error != null) {
      return _EstadoError(mensaje: error, onReintentar: _cargarDia);
    }
    // Estados 2 y 3: con marcas o sin ellas. La diferencia la pinta
    // ResumenDia con "—:— a —:—", como en la maqueta.
    return _Contenido(
      asistencia: _asistencia,
      marcando: _marcando,
      aviso: _aviso,
      onMarcar: _marcar,
      onAccionAviso: _ejecutar,
    );
  }
}

/// Cabecera verde de la guía: "Colaborador / Asistencia".
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
            'Asistencia',
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

/// El botón, el resumen del día y el aviso, centrados como en la maqueta.
class _Contenido extends StatelessWidget {
  final Asistencia? asistencia;
  final bool marcando;
  final _Aviso? aviso;
  final VoidCallback onMarcar;
  final Future<void> Function(_AccionAviso) onAccionAviso;

  const _Contenido({
    required this.asistencia,
    required this.marcando,
    required this.aviso,
    required this.onMarcar,
    required this.onAccionAviso,
  });

  @override
  Widget build(BuildContext context) {
    final pendiente = asistencia?.pendiente ?? MarcaPendiente.entrada;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      children: [
        Center(
          child: BotonMarcar(
            pendiente: pendiente,
            ocupado: marcando,
            onMarcar: onMarcar,
          ),
        ),
        const SizedBox(height: 14),
        ResumenDia(asistencia: asistencia),
        if (aviso != null) ...[
          const SizedBox(height: 18),
          _TarjetaAviso(aviso: aviso!, onAccion: onAccionAviso),
        ],
      ],
    );
  }
}

/// Qué ofrece el aviso además del texto.
enum _AccionAviso {
  ninguna,
  reintentar,
  reintentarPermiso,
  abrirAjustes,
  abrirAjustesUbicacion,
}

class _Aviso {
  final String texto;
  final _AccionAviso accion;
  final bool exito;

  const _Aviso({required this.texto, required this.accion, this.exito = false});
}

/// El aviso bajo el botón. Verde si la marca quedó grabada, rojo si algo
/// impide marcar.
class _TarjetaAviso extends StatelessWidget {
  final _Aviso aviso;
  final Future<void> Function(_AccionAviso) onAccion;

  const _TarjetaAviso({required this.aviso, required this.onAccion});

  @override
  Widget build(BuildContext context) {
    final fondo = aviso.exito ? AppColors.verde100 : AppColors.rojo100;
    final tinte = aviso.exito ? AppColors.verde600 : AppColors.rojo700;
    final icono = aviso.exito ? Icons.check_rounded : Icons.location_off;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 18, color: tinte),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  aviso.texto,
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: tinte),
                ),
              ),
            ],
          ),
          if (aviso.accion != _AccionAviso.ninguna) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onAccion(aviso.accion),
                child: Text(_etiqueta(aviso.accion)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _etiqueta(_AccionAviso accion) => switch (accion) {
    _AccionAviso.abrirAjustes => 'Abrir ajustes',
    _AccionAviso.abrirAjustesUbicacion => 'Encender ubicación',
    _AccionAviso.reintentarPermiso => 'Permitir ubicación',
    _AccionAviso.reintentar => 'Reintentar',
    _AccionAviso.ninguna => '',
  };
}

/// Estado 4: no se pudo consultar el día.
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
