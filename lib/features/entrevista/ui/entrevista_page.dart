import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/model/entrevista.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Datos de la entrevista y confirmación de asistencia (T2-19 · CU-15).
/// Se abre con el código de seguimiento (ej. POST-8F4K2A1C).
///
/// Estados para la evidencia, igual que SeguimientoPage:
///   1. Cargando             -> spinner
///   2. Por confirmar        -> datos + botón "Confirmar asistencia"
///   3. Confirmada           -> datos + marca verde, sin botón
///   4. Sin entrevista       -> mensaje amable
///   5. Error al consultar   -> mensaje + reintentar
///   6. Error al confirmar   -> aviso rojo, los datos siguen en pantalla
///
/// Ubicación:  lib/features/entrevista/ui/entrevista_page.dart
class EntrevistaPage extends StatefulWidget {
  final String codigo;
  final EntrevistaService service;

  const EntrevistaPage({
    super.key,
    required this.codigo,
    required this.service,
  });

  @override
  State<EntrevistaPage> createState() => _EntrevistaPageState();
}

class _EntrevistaPageState extends State<EntrevistaPage> {
  late Future<Entrevista?> _futuro;
  var _confirmando = false;
  String? _errorConfirmar;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _errorConfirmar = null;
      _futuro = widget.service.porCodigo(widget.codigo);
    });
  }

  Future<void> _confirmar() async {
    setState(() {
      _confirmando = true;
      _errorConfirmar = null;
    });
    try {
      final actualizada = await widget.service.confirmar(widget.codigo);
      if (!mounted) return;
      // Con llaves y no con flecha: la flecha devolvería el Future asignado
      // y setState lanza "callback argument returned a Future".
      setState(() {
        _futuro = Future.value(actualizada);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Listo! Confirmaste tu asistencia.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorConfirmar = e.toString());
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Cabecera(codigo: widget.codigo),
          Expanded(
            child: FutureBuilder<Entrevista?>(
              future: _futuro,
              builder: (context, snap) {
                // Estado 1: cargando
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.verde600),
                  );
                }
                // Estado 5: error al consultar
                if (snap.hasError) {
                  return _EstadoError(
                    mensaje: snap.error.toString(),
                    onReintentar: _cargar,
                  );
                }
                final entrevista = snap.data;
                // Estado 4: no hay entrevista programada
                if (entrevista == null) return const _EstadoVacio();
                // Estados 2, 3 y 6
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: _Contenido(
                    entrevista: entrevista,
                    confirmando: _confirmando,
                    errorConfirmar: _errorConfirmar,
                    onConfirmar: _confirmar,
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
                  'Mi entrevista',
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

/// Estados 2, 3 y 6: tarjeta con los datos y, debajo, la acción.
class _Contenido extends StatelessWidget {
  final Entrevista entrevista;
  final bool confirmando;
  final String? errorConfirmar;
  final VoidCallback onConfirmar;

  const _Contenido({
    required this.entrevista,
    required this.confirmando,
    required this.errorConfirmar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final e = entrevista;
    final esVirtual = e.modalidad == ModalidadEntrevista.virtual;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.vacanteTitulo,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        color: AppColors.tinta,
                      ),
                    ),
                  ),
                  _ChipEstado(estado: e.estado),
                ],
              ),
              const SizedBox(height: 16),
              _Dato(
                icono: Icons.event_outlined,
                titulo: 'Fecha',
                valor: e.fechaLarga,
              ),
              _Dato(
                icono: Icons.schedule_outlined,
                titulo: 'Hora',
                valor: e.horaTexto,
              ),
              _Dato(
                icono: esVirtual
                    ? Icons.videocam_outlined
                    : Icons.apartment_outlined,
                titulo: 'Modalidad',
                valor: e.modalidad.etiqueta,
              ),
              if (!esVirtual && e.lugar != null)
                _Dato(
                  icono: Icons.place_outlined,
                  titulo: 'Lugar',
                  valor: e.lugar!,
                ),
              if (esVirtual && e.enlace != null)
                _Dato(
                  icono: Icons.link,
                  titulo: 'Enlace',
                  valor: e.enlace!,
                  copiable: true,
                ),
              if (e.entrevistador != null)
                _Dato(
                  icono: Icons.person_outline,
                  titulo: 'Te entrevista',
                  valor: e.entrevistador!,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (errorConfirmar != null) ...[
          _Aviso(
            texto: errorConfirmar!,
            icono: Icons.error_outline,
            fondo: AppColors.rojo100,
            color: AppColors.rojo700,
          ),
          const SizedBox(height: 12),
        ],
        _Accion(
          entrevista: e,
          confirmando: confirmando,
          onConfirmar: onConfirmar,
        ),
      ],
    );
  }
}

/// Lo que va debajo de la tarjeta según el estado de la entrevista.
class _Accion extends StatelessWidget {
  final Entrevista entrevista;
  final bool confirmando;
  final VoidCallback onConfirmar;

  const _Accion({
    required this.entrevista,
    required this.confirmando,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    switch (entrevista.estado) {
      case EstadoEntrevista.confirmada:
        return const _Aviso(
          texto: 'Confirmaste tu asistencia. Te esperamos.',
          icono: Icons.check_circle_outline,
          fondo: AppColors.verde100,
          color: AppColors.verde600,
        );
      case EstadoEntrevista.cancelada:
        return const _Aviso(
          texto:
              'Esta entrevista fue cancelada. La empresa se pondrá en '
              'contacto contigo.',
          icono: Icons.event_busy_outlined,
          fondo: AppColors.rojo100,
          color: AppColors.rojo700,
        );
      case EstadoEntrevista.reprogramada:
        return const _Aviso(
          texto:
              'Tu entrevista fue reprogramada. Actualiza para ver la '
              'nueva fecha.',
          icono: Icons.update,
          fondo: AppColors.ambar100,
          color: AppColors.ambar700,
        );
      case EstadoEntrevista.programada:
        if (entrevista.yaPaso) {
          return const _Aviso(
            texto: 'La fecha de esta entrevista ya pasó.',
            icono: Icons.history,
            fondo: AppColors.ambar100,
            color: AppColors.ambar700,
          );
        }
        return ElevatedButton(
          onPressed: confirmando ? null : onConfirmar,
          child: confirmando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirmar asistencia'),
        );
    }
  }
}

class _ChipEstado extends StatelessWidget {
  final EstadoEntrevista estado;

  const _ChipEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (fondo, color) = switch (estado) {
      EstadoEntrevista.confirmada => (AppColors.verde100, AppColors.verde600),
      EstadoEntrevista.cancelada => (AppColors.rojo100, AppColors.rojo700),
      _ => (AppColors.ambar100, AppColors.ambar700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Una fila "icono · título / valor". Si es copiable, se copia de un toque
/// (no hay url_launcher en el proyecto, así que el enlace se copia).
class _Dato extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final bool copiable;

  const _Dato({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.copiable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: AppColors.verde600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.tinta2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 14,
                    color: copiable ? AppColors.verde600 : AppColors.tinta,
                  ),
                ),
              ],
            ),
          ),
          if (copiable)
            IconButton(
              tooltip: 'Copiar enlace',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 18, color: AppColors.tinta2),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: valor));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
              },
            ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color fondo;
  final Color color;

  const _Aviso({
    required this.texto,
    required this.icono,
    required this.fondo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppRadii.boton),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Estado 4: la postulación todavía no tiene entrevista. No es un error.
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 48,
              color: AppColors.tinta2,
            ),
            const SizedBox(height: 12),
            const Text(
              'Todavía no tienes una entrevista programada',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Si tu postulación avanza a la etapa de entrevista, aquí verás '
              'la fecha y el lugar. Revisa también que el código esté bien '
              'escrito.',
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

/// Estado 5: no se pudo consultar.
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
