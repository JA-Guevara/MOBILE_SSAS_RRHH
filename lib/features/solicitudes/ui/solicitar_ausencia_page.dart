import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/solicitud_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/tarjeta_saldo.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/documento_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/nueva_solicitud.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/opciones_solicitud.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/widgets/campo_fecha.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/widgets/condiciones_tipo.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/widgets/selector_documento.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Solicitar permiso o vacaciones (T3-19 · HU-16 · CU-24).
///
/// El colaborador ve su saldo de vacaciones ANTES de enviar, elige el tipo
/// de ausencia, las fechas (los días hábiles se calculan solos), escribe el
/// motivo y, si el tipo lo exige, adjunta el documento de respaldo.
///
/// Estados para la evidencia:
///   1. Cargando          -> spinner
///   2. Formulario        -> saldo + campos  (capturas "con saldo", "sin saldo",
///                           "saldo insuficiente", "requiere documento")
///   3. Vacío             -> la empresa no configuró tipos de ausencia
///   4. Error al cargar   -> mensaje + reintentar ("error" y "sesión")
///   5. Error al enviar   -> aviso rojo; el formulario no se pierde
///   6. Enviada           -> resumen de la solicitud pendiente
///
/// Ubicación:  lib/features/solicitudes/ui/solicitar_ausencia_page.dart
class SolicitarAusenciaPage extends StatefulWidget {
  final SolicitudesService service;

  /// El "hoy" de la pantalla. Se inyecta para que las pruebas no dependan
  /// del día en que corren; en la app es DateTime.now.
  final DateTime Function()? reloj;

  const SolicitarAusenciaPage({super.key, required this.service, this.reloj});

  @override
  State<SolicitarAusenciaPage> createState() => _SolicitarAusenciaPageState();
}

class _SolicitarAusenciaPageState extends State<SolicitarAusenciaPage> {
  late Future<OpcionesSolicitud> _futuro;

  /// La solicitud recién creada. Mientras sea null se ve el formulario.
  SolicitudAusencia? _enviada;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _enviada = null;
      _futuro = widget.service.opciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enviada = _enviada;

    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: enviada != null
                // Estado 6: enviada
                ? _SolicitudEnviada(solicitud: enviada, onOtra: _cargar)
                : FutureBuilder<OpcionesSolicitud>(
                    future: _futuro,
                    builder: (context, snap) {
                      // Estado 1: cargando
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.verde600,
                          ),
                        );
                      }
                      // Estado 4: error al cargar
                      if (snap.hasError) {
                        return _EstadoError(
                          mensaje: mensajeDeErrorSolicitudes(snap.error!),
                          onReintentar: _cargar,
                        );
                      }
                      final opciones = snap.data!;
                      // Estado 3: no hay nada que pedir
                      if (opciones.tipos.isEmpty) return const _EstadoVacio();
                      // Estados 2 y 5: el formulario
                      return _Formulario(
                        opciones: opciones,
                        service: widget.service,
                        hoy: DateUtils.dateOnly(
                          (widget.reloj ?? DateTime.now)(),
                        ),
                        onEnviada: (s) => setState(() => _enviada = s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía: "Colaborador / Solicitar permiso o vacaciones".
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
                  'Solicitar permiso o vacaciones',
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

/// Estados 2 y 5: el formulario, con el saldo arriba.
class _Formulario extends StatefulWidget {
  final OpcionesSolicitud opciones;
  final SolicitudesService service;
  final DateTime hoy;
  final ValueChanged<SolicitudAusencia> onEnviada;

  const _Formulario({
    required this.opciones,
    required this.service,
    required this.hoy,
    required this.onEnviada,
  });

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();

  TipoAusencia? _tipo;
  DateTime? _inicio;
  DateTime? _fin;
  DocumentoAdjunto? _documento;

  var _autovalidar = false;
  var _enviando = false;
  String? _errorEnvio;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  /// Días hábiles del rango, o null mientras falte alguna fecha.
  int? get _dias {
    final inicio = _inicio;
    final fin = _fin;
    if (inicio == null || fin == null) return null;
    return NuevaSolicitud.diasHabiles(inicio, fin);
  }

  /// Por qué no se puede enviar con estas fechas, o null si se puede.
  String? get _problema {
    final tipo = _tipo;
    final dias = _dias;
    if (tipo == null || dias == null) return null;
    return NuevaSolicitud.problemaConLosDias(
      tipo: tipo,
      dias: dias,
      saldo: widget.opciones.saldo,
    );
  }

  bool get _faltaDocumento =>
      (_tipo?.requiereDocumento ?? false) && _documento == null;

  Future<void> _elegirFecha({required bool esInicio}) async {
    final hoy = widget.hoy;
    // Se permite hasta 30 días atrás: una baja médica se pide a veces
    // después de empezar. El backend decide si la acepta.
    final primera = DateTime(hoy.year, hoy.month, hoy.day - 30);
    final ultima = DateTime(hoy.year + 1, hoy.month, hoy.day);

    final elegida = await showDatePicker(
      context: context,
      initialDate: esInicio ? (_inicio ?? hoy) : (_fin ?? _inicio ?? hoy),
      // La fecha de fin no puede ser anterior a la de inicio.
      firstDate: esInicio ? primera : (_inicio ?? primera),
      lastDate: ultima,
      helpText: esInicio ? 'Fecha de inicio' : 'Fecha de fin',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );
    if (elegida == null || !mounted) return;

    setState(() {
      _errorEnvio = null;
      if (esInicio) {
        _inicio = elegida;
        // Si el fin quedó antes del nuevo inicio, ya no vale.
        if (_fin != null && _fin!.isBefore(elegida)) _fin = null;
      } else {
        _fin = elegida;
      }
    });
  }

  Future<void> _enviar() async {
    setState(() {
      _autovalidar = true;
      _errorEnvio = null;
    });

    final formOk = _formKey.currentState?.validate() ?? false;
    final tipo = _tipo;
    final inicio = _inicio;
    final fin = _fin;
    if (!formOk ||
        tipo == null ||
        inicio == null ||
        fin == null ||
        _faltaDocumento ||
        _problema != null) {
      return;
    }

    setState(() => _enviando = true);
    try {
      final creada = await widget.service.enviar(
        NuevaSolicitud(
          tipo: tipo,
          fechaInicio: inicio,
          fechaFin: fin,
          motivo: _motivo.text,
          // Solo se manda si el tipo lo pide: si el colaborador cambió de
          // tipo, el archivo anterior no se cuela.
          documento: tipo.requiereDocumento ? _documento : null,
        ),
      );
      if (!mounted) return;
      widget.onEnviada(creada);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorEnvio = mensajeDeErrorEnvio(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldo = widget.opciones.saldo;
    final tipo = _tipo;
    final dias = _dias;
    final problema = _problema;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidar
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Lo primero que pide la tarea: el saldo, antes de enviar.
          if (saldo != null)
            TarjetaSaldo(saldo: saldo, diasSolicitados: null)
          else
            const _SinSaldo(),
          const SizedBox(height: 16),
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
                // ------------------------------------------------ tipo
                const EtiquetaCampo(
                  texto: 'Tipo de ausencia',
                  obligatorio: true,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<TipoAusencia>(
                  initialValue: tipo,
                  isExpanded: true,
                  hint: const Text(
                    'Elige el tipo',
                    style: TextStyle(color: AppColors.tinta2),
                  ),
                  style: const TextStyle(fontSize: 14, color: AppColors.tinta),
                  decoration: decoracionCampo(),
                  items: [
                    for (final t in widget.opciones.tipos)
                      DropdownMenuItem(value: t, child: Text(t.nombre)),
                  ],
                  onChanged: _enviando
                      ? null
                      : (t) => setState(() {
                          _tipo = t;
                          _errorEnvio = null;
                        }),
                  validator: (t) =>
                      t == null ? 'Elige el tipo de ausencia.' : null,
                ),
                if (tipo != null) ...[
                  const SizedBox(height: 8),
                  CondicionesTipo(tipo: tipo),
                ],
                const SizedBox(height: 14),

                // ---------------------------------------------- fechas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CampoFecha(
                        etiqueta: 'Desde',
                        valor: _inicio,
                        onTap: _enviando
                            ? null
                            : () => _elegirFecha(esInicio: true),
                        validador: (_) => _inicio == null
                            ? 'Elige la fecha de inicio.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CampoFecha(
                        etiqueta: 'Hasta',
                        valor: _fin,
                        onTap: _enviando
                            ? null
                            : () => _elegirFecha(esInicio: false),
                        validador: (_) =>
                            _fin == null ? 'Elige la fecha de fin.' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ------------------------------- días (se calculan solos)
                const EtiquetaCampo(
                  texto: 'Días solicitados',
                  ayuda: 'se calculan solos, de lunes a viernes',
                ),
                const SizedBox(height: 6),
                _DiasSolicitados(dias: dias),
                if (problema != null) ...[
                  const SizedBox(height: 8),
                  _Aviso(
                    texto: problema,
                    icono: Icons.error_outline,
                    fondo: AppColors.rojo100,
                    color: AppColors.rojo700,
                  ),
                ] else if (tipo != null &&
                    tipo.descuentaVacacion &&
                    dias != null &&
                    saldo?.diasSaldo != null) ...[
                  const SizedBox(height: 8),
                  _Aviso(
                    texto: _textoRestante(saldo!.diasSaldo! - dias),
                    icono: Icons.beach_access_outlined,
                    fondo: AppColors.verde100,
                    color: AppColors.verde600,
                  ),
                ],
                const SizedBox(height: 14),

                // ---------------------------------------------- motivo
                const EtiquetaCampo(texto: 'Motivo', obligatorio: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _motivo,
                  enabled: !_enviando,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14, color: AppColors.tinta),
                  decoration: decoracionCampo().copyWith(
                    hintText: 'Cuéntale a tu jefe por qué la pides.',
                    hintStyle: const TextStyle(color: AppColors.tinta2),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Escribe el motivo de la solicitud.'
                      : null,
                ),

                // -------------------------- documento (solo si se exige)
                if (tipo?.requiereDocumento ?? false) ...[
                  const SizedBox(height: 8),
                  SelectorDocumento(
                    documento: _documento,
                    habilitado: !_enviando,
                    error: _autovalidar && _faltaDocumento
                        ? 'Este tipo de ausencia exige un documento de '
                              'respaldo.'
                        : null,
                    onCambio: (d) => setState(() => _documento = d),
                  ),
                ],
              ],
            ),
          ),
          if (_errorEnvio != null) ...[
            const SizedBox(height: 12),
            _Aviso(
              texto: _errorEnvio!,
              icono: Icons.cloud_off,
              fondo: AppColors.rojo100,
              color: AppColors.rojo700,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
  }
}

/// "Si tu jefe la aprueba, te quedarán 2 días de vacación."
String _textoRestante(double restante) {
  final dias = SaldoVacacion.dias(restante);
  return restante == 1
      ? 'Si tu jefe la aprueba, te quedará 1 día de vacación.'
      : 'Si tu jefe la aprueba, te quedarán $dias días de vacación.';
}

/// La caja de días: parece un campo, pero no se escribe; la llena el rango.
class _DiasSolicitados extends StatelessWidget {
  final int? dias;

  const _DiasSolicitados({required this.dias});

  @override
  Widget build(BuildContext context) {
    final d = dias;
    final texto = switch (d) {
      null => 'Elige las fechas',
      1 => '1 día hábil',
      _ => '$d días hábiles',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mentaBg,
        borderRadius: BorderRadius.circular(AppRadii.boton),
        border: Border.all(color: AppColors.borde),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: d == null ? FontWeight.normal : FontWeight.w600,
          color: d == null ? AppColors.tinta2 : AppColors.tinta,
        ),
      ),
    );
  }
}

/// Aviso con icono: rojo si algo impide enviar, verde si solo informa.
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
            child: Text(
              texto,
              style: TextStyle(fontSize: 13, height: 1.35, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Todavía no tiene vacaciones asignadas. No impide pedir los demás tipos.
class _SinSaldo extends StatelessWidget {
  const _SinSaldo();

  @override
  Widget build(BuildContext context) {
    return const _Aviso(
      texto:
          'Todavía no tienes saldo de vacaciones asignado. Puedes pedir '
          'los demás tipos de ausencia.',
      icono: Icons.info_outline,
      fondo: AppColors.ambar100,
      color: AppColors.ambar700,
    );
  }
}

/// Estado 6: la solicitud quedó registrada y espera al jefe.
class _SolicitudEnviada extends StatelessWidget {
  final SolicitudAusencia solicitud;
  final VoidCallback onOtra;

  const _SolicitudEnviada({required this.solicitud, required this.onOtra});

  @override
  Widget build(BuildContext context) {
    final tipo = solicitud.tipo;
    final dias = solicitud.diasSolicitados;
    final estado = solicitud.estaPendiente
        ? 'Pendiente de aprobación'
        : (solicitud.estadoCrudo ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.carta,
            borderRadius: BorderRadius.circular(AppRadii.tarjeta),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.verde100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.verde600,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Solicitud enviada',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  color: AppColors.tinta,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Quedó registrada y la verá tu jefe para aprobarla o '
                'rechazarla.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.tinta2),
              ),
              const SizedBox(height: 18),
              if (tipo != null) _Dato(etiqueta: 'Tipo', valor: tipo.nombre),
              if (solicitud.rangoFechas.isNotEmpty)
                _Dato(etiqueta: 'Fechas', valor: solicitud.rangoFechas),
              if (dias != null)
                _Dato(
                  etiqueta: 'Días',
                  valor: dias == 1
                      ? '1 día hábil'
                      : '${SaldoVacacion.dias(dias)} días hábiles',
                ),
              if (solicitud.documentoUrl != null)
                const _Dato(etiqueta: 'Documento', valor: 'Adjunto'),
              _Dato(etiqueta: 'Estado', valor: estado),
            ],
          ),
        ),
        if (tipo?.descuentaVacacion ?? false) ...[
          const SizedBox(height: 12),
          const _Aviso(
            texto:
                'Los días se descontarán de tu saldo de vacaciones cuando '
                'tu jefe la apruebe.',
            icono: Icons.beach_access_outlined,
            fondo: AppColors.verde100,
            color: AppColors.verde600,
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onOtra,
          child: const Text('Hacer otra solicitud'),
        ),
      ],
    );
  }
}

/// Una fila "etiqueta · valor" del resumen.
class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.tinta,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado 3: la empresa no configuró ningún tipo de ausencia.
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
              'Tu empresa todavía no configuró tipos de ausencia',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Consulta con Recursos Humanos para pedir un permiso o tus '
              'vacaciones.',
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
