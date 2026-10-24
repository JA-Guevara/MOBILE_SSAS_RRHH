import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/dialogo_respuesta.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/solicitud_card.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/tarjeta_saldo.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Detalle de una solicitud y sus dos acciones (T3-22), segunda pantalla.
///
/// Aprobar y rechazar son irreversibles desde el móvil, así que ninguna se
/// ejecuta de un solo toque: pasan por [mostrarDialogoRespuesta].
///
/// Ubicación:  lib/features/aprobaciones/ui/solicitud_detalle_page.dart
class SolicitudDetallePage extends StatefulWidget {
  final String solicitudId;

  /// Se recibe de la bandeja para pintar la cabecera desde el primer frame.
  final String solicitante;

  final AprobacionesService service;

  const SolicitudDetallePage({
    super.key,
    required this.solicitudId,
    required this.solicitante,
    required this.service,
  });

  @override
  State<SolicitudDetallePage> createState() => _SolicitudDetallePageState();
}

class _SolicitudDetallePageState extends State<SolicitudDetallePage> {
  var _cargando = true;
  String? _errorCarga;
  SolicitudAusencia? _solicitud;

  /// True mientras viaja la aprobación o el rechazo: todo bloqueado.
  var _respondiendo = false;

  /// Aviso al pie: la confirmación de lo hecho, o por qué no se pudo.
  String? _aviso;
  var _avisoEsExito = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });

    try {
      final solicitud = await widget.service.detalle(widget.solicitudId);
      if (!mounted) return;
      setState(() {
        _solicitud = solicitud;
        _cargando = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = mensajeDeErrorAprobaciones(e);
        _cargando = false;
      });
    }
  }

  /// Pide confirmación y, solo si el jefe confirma, ejecuta la acción.
  Future<void> _responder(AccionRespuesta accion) async {
    final solicitud = _solicitud;
    if (solicitud == null || _respondiendo) return;

    final observacion = await mostrarDialogoRespuesta(
      context,
      accion: accion,
      solicitante: solicitud.solicitante,
      resumen: solicitud.subtitulo,
    );

    // null = canceló. Cadena vacía = aprobó sin escribir nada.
    if (observacion == null) return;
    if (!mounted) return;

    setState(() {
      _respondiendo = true;
      _aviso = null;
    });

    try {
      final actualizada = accion == AccionRespuesta.aprobar
          ? await widget.service.aprobar(solicitud.id, observacion: observacion)
          : await widget.service.rechazar(
              solicitud.id,
              observacion: observacion,
            );

      if (!mounted) return;
      setState(() {
        _solicitud = actualizada;
        _respondiendo = false;
        _avisoEsExito = true;
        _aviso = accion == AccionRespuesta.aprobar
            ? 'Solicitud aprobada. El empleado recibirá la respuesta.'
            : 'Solicitud rechazada. El empleado verá tu observación.';
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _respondiendo = false;
        _avisoEsExito = false;
        _aviso = mensajeDeErrorAprobaciones(e);
      });
      // Si otro jefe respondió antes (409), el estado que tenemos ya no
      // vale: se recarga para que los botones desaparezcan.
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Cabecera(solicitante: widget.solicitante),
          Expanded(child: _cuerpo()),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verde600),
      );
    }

    final error = _errorCarga;
    if (error != null) {
      return _EstadoError(mensaje: error, onReintentar: _cargar);
    }

    final solicitud = _solicitud;
    if (solicitud == null) {
      return _EstadoError(
        mensaje: mensajeDeErrorAprobaciones(Object()),
        onReintentar: _cargar,
      );
    }

    return _Contenido(
      solicitud: solicitud,
      respondiendo: _respondiendo,
      aviso: _aviso,
      avisoEsExito: _avisoEsExito,
      onResponder: _responder,
    );
  }
}

class _Cabecera extends StatelessWidget {
  final String solicitante;

  const _Cabecera({required this.solicitante});

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
                  'Solicitud de ausencia',
                  style: TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  solicitante,
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

class _Contenido extends StatelessWidget {
  final SolicitudAusencia solicitud;
  final bool respondiendo;
  final String? aviso;
  final bool avisoEsExito;
  final Future<void> Function(AccionRespuesta) onResponder;

  const _Contenido({
    required this.solicitud,
    required this.respondiendo,
    required this.aviso,
    required this.avisoEsExito,
    required this.onResponder,
  });

  @override
  Widget build(BuildContext context) {
    final saldo = solicitud.saldo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Datos(solicitud: solicitud),

        // El saldo solo cuando el tipo descuenta vacación: si no, no cambia
        // y enseñarlo sería ruido.
        if (solicitud.afectaVacaciones && saldo != null) ...[
          const SizedBox(height: 12),
          TarjetaSaldo(
            saldo: saldo,
            diasSolicitados: solicitud.diasSolicitados,
          ),
        ],

        if (solicitud.faltaDocumento) ...[
          const SizedBox(height: 12),
          const _AvisoCaja(
            texto:
                'Este tipo de ausencia exige documento de respaldo y la '
                'solicitud no trae ninguno.',
            exito: false,
          ),
        ],

        const SizedBox(height: 16),

        if (solicitud.sePuedeResponder)
          _Acciones(respondiendo: respondiendo, onResponder: onResponder)
        else
          _YaRespondida(solicitud: solicitud),

        if (aviso != null) ...[
          const SizedBox(height: 14),
          _AvisoCaja(texto: aviso!, exito: avisoEsExito),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

/// La ficha: tipo, fechas, días, motivo y documento.
class _Datos extends StatelessWidget {
  final SolicitudAusencia solicitud;

  const _Datos({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final tipo = solicitud.tipo;

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
                child: Text(
                  solicitud.solicitante,
                  style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
                ),
              ),
              if (tipo != null) ChipTipoAusencia(nombre: tipo.nombre),
            ],
          ),
          if (tipo != null && tipo.subtitulo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tipo.subtitulo,
              style: const TextStyle(fontSize: 11.5, color: AppColors.tinta2),
            ),
          ],
          const Divider(height: 22, color: AppColors.borde),
          _Dato(etiqueta: 'Fechas', valor: solicitud.rangoFechas),
          _Dato(etiqueta: 'Días solicitados', valor: solicitud.diasTexto),
          if (solicitud.motivo != null)
            _Dato(etiqueta: 'Motivo', valor: solicitud.motivo!),
          if (solicitud.documentoUrl != null)
            const _Dato(etiqueta: 'Documento', valor: 'Adjunto'),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    if (valor.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 11.5, color: AppColors.tinta2),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.tinta,
            ),
          ),
        ],
      ),
    );
  }
}

/// Los dos botones. Rechazar va en secundario para que no se pulse por
/// inercia: es la acción que más molesta si se hace sin querer.
class _Acciones extends StatelessWidget {
  final bool respondiendo;
  final Future<void> Function(AccionRespuesta) onResponder;

  const _Acciones({required this.respondiendo, required this.onResponder});

  @override
  Widget build(BuildContext context) {
    if (respondiendo) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: CircularProgressIndicator(color: AppColors.verde600),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => onResponder(AccionRespuesta.aprobar),
            child: const Text('Aprobar'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => onResponder(AccionRespuesta.rechazar),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rojo700,
              side: const BorderSide(color: AppColors.rojo700),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.boton),
              ),
            ),
            child: const Text('Rechazar'),
          ),
        ),
      ],
    );
  }
}

/// Cuando la solicitud ya no está pendiente: sin botones, con lo decidido.
class _YaRespondida extends StatelessWidget {
  final SolicitudAusencia solicitud;

  const _YaRespondida({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final aprobada = solicitud.estado == EstadoSolicitud.aprobada;
    final tinte = aprobada ? AppColors.verde600 : AppColors.rojo700;
    final fondo = aprobada ? AppColors.verde100 : AppColors.rojo100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                aprobada ? Icons.check_rounded : Icons.close_rounded,
                size: 18,
                color: tinte,
              ),
              const SizedBox(width: 10),
              Text(
                _texto(solicitud),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: tinte,
                ),
              ),
            ],
          ),
          if (solicitud.observacionAprobador != null) ...[
            const SizedBox(height: 8),
            Text(
              solicitud.observacionAprobador!,
              style: TextStyle(fontSize: 12.5, height: 1.35, color: tinte),
            ),
          ],
        ],
      ),
    );
  }

  /// Si el estado no se reconoce, se muestra el literal del backend en vez
  /// de inventar uno.
  static String _texto(SolicitudAusencia solicitud) =>
      switch (solicitud.estado) {
        EstadoSolicitud.aprobada => 'Solicitud aprobada',
        EstadoSolicitud.rechazada => 'Solicitud rechazada',
        EstadoSolicitud.cancelada => 'Solicitud cancelada',
        _ => 'Estado: ${solicitud.estadoCrudo ?? 'desconocido'}',
      };
}

/// Caja de aviso al pie: verde si salió bien, roja si no.
class _AvisoCaja extends StatelessWidget {
  final String texto;
  final bool exito;

  const _AvisoCaja({required this.texto, required this.exito});

  @override
  Widget build(BuildContext context) {
    final tinte = exito ? AppColors.verde600 : AppColors.rojo700;
    final fondo = exito ? AppColors.verde100 : AppColors.rojo100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            exito ? Icons.check_rounded : Icons.error_outline,
            size: 18,
            color: tinte,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 12.5, height: 1.35, color: tinte),
            ),
          ),
        ],
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
