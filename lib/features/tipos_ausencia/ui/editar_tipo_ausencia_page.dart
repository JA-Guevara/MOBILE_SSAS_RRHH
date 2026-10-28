import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/model/reglas_tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/ui/widgets/cabecera_admin.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Editar un tipo de ausencia (T3-30): los ocho campos de la tabla.
///
/// Estados para la evidencia:
///   1. Formulario       -> con los datos actuales; "Guardar" apagado
///                          hasta que algo cambie
///   2. Con errores      -> nombre vacío, código repetido, tope fuera de rango
///   3. Guardando        -> spinner en el botón, campos bloqueados
///   4. Error al guardar -> aviso rojo; lo escrito no se pierde
///   Al guardar bien, vuelve a la lista con el tipo guardado.
///
/// Ubicación:  lib/features/tipos_ausencia/ui/editar_tipo_ausencia_page.dart
class EditarTipoAusenciaPage extends StatefulWidget {
  final TiposAusenciaService service;
  final TipoAusencia tipo;

  /// Los códigos de los demás tipos de la empresa: el código es único.
  final List<String> codigosDeOtros;

  const EditarTipoAusenciaPage({
    super.key,
    required this.service,
    required this.tipo,
    this.codigosDeOtros = const [],
  });

  @override
  State<EditarTipoAusenciaPage> createState() => _EditarTipoAusenciaPageState();
}

class _EditarTipoAusenciaPageState extends State<EditarTipoAusenciaPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.tipo.nombre);
  late final _codigo = TextEditingController(text: widget.tipo.codigo ?? '');
  late final _tope = TextEditingController(
    text: widget.tipo.diasMaximosAnio?.toString() ?? '',
  );

  late var _esRemunerado = widget.tipo.esRemunerado;
  late var _descuentaVacacion = widget.tipo.descuentaVacacion;
  late var _requiereAprobacion = widget.tipo.requiereAprobacion;
  late var _requiereDocumento = widget.tipo.requiereDocumento;
  late var _activo = widget.tipo.activo;

  var _autovalidar = false;
  var _guardando = false;
  String? _errorGuardado;

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _tope.dispose();
    super.dispose();
  }

  /// El tipo tal como quedaría si se guarda ahora.
  TipoAusencia get _editado => TipoAusencia(
    id: widget.tipo.id,
    empresaId: widget.tipo.empresaId,
    nombre: _nombre.text.trim(),
    codigo: ReglasTipoAusencia.normalizarCodigo(_codigo.text),
    esRemunerado: _esRemunerado,
    descuentaVacacion: _descuentaVacacion,
    diasMaximosAnio: ReglasTipoAusencia.leerTope(_tope.text),
    requiereAprobacion: _requiereAprobacion,
    requiereDocumento: _requiereDocumento,
    activo: _activo,
  );

  bool get _hayCambios => ReglasTipoAusencia.cambio(widget.tipo, _editado);

  /// Cualquier cambio borra el error anterior y recalcula "Guardar".
  void _cambiar(VoidCallback cambio) => setState(() {
    cambio();
    _errorGuardado = null;
  });

  Future<void> _guardar() async {
    setState(() {
      _autovalidar = true;
      _errorGuardado = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    try {
      final guardado = await widget.service.guardar(_editado);
      if (!mounted) return;
      Navigator.of(context).pop(guardado);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorGuardado = mensajeDeErrorGuardado(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = !_guardando;

    return Scaffold(
      body: Column(
        children: [
          CabeceraAdmin(
            etiqueta: 'Tipos de ausencia',
            titulo: widget.tipo.nombre,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidar
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Seccion(
                    titulo: 'Datos',
                    children: [
                      CampoFormulario(
                        etiqueta: 'Nombre',
                        controller: _nombre,
                        obligatorio: true,
                        habilitado: habilitado,
                        validador: ReglasTipoAusencia.nombre,
                        onCambio: (_) => _cambiar(() {}),
                      ),
                      CampoFormulario(
                        etiqueta: 'Código',
                        controller: _codigo,
                        obligatorio: true,
                        ayuda: 'único en la empresa',
                        habilitado: habilitado,
                        formateadores: [_mayusculas],
                        validador: (v) =>
                            ReglasTipoAusencia.codigo(v, widget.codigosDeOtros),
                        onCambio: (_) => _cambiar(() {}),
                      ),
                      CampoFormulario(
                        etiqueta: 'Tope anual (días)',
                        controller: _tope,
                        ayuda: 'vacío = sin tope',
                        habilitado: habilitado,
                        tipoTeclado: TextInputType.number,
                        accionTeclado: TextInputAction.done,
                        formateadores: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validador: ReglasTipoAusencia.tope,
                        onCambio: (_) => _cambiar(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Seccion(
                    titulo: 'Condiciones',
                    children: [
                      _Interruptor(
                        titulo: 'Con goce de haber',
                        detalle: 'El día de ausencia se paga.',
                        valor: _esRemunerado,
                        onCambio: habilitado
                            ? (v) => _cambiar(() => _esRemunerado = v)
                            : null,
                      ),
                      _Interruptor(
                        titulo: 'Descuenta del saldo de vacaciones',
                        detalle:
                            'Los días aprobados se restan de las vacaciones '
                            'del colaborador.',
                        valor: _descuentaVacacion,
                        onCambio: habilitado
                            ? (v) => _cambiar(() => _descuentaVacacion = v)
                            : null,
                      ),
                      _Interruptor(
                        titulo: 'Requiere aprobación del jefe',
                        detalle:
                            'La solicitud pasa por la bandeja del jefe '
                            'directo.',
                        valor: _requiereAprobacion,
                        onCambio: habilitado
                            ? (v) => _cambiar(() => _requiereAprobacion = v)
                            : null,
                      ),
                      _Interruptor(
                        titulo: 'Requiere documento de respaldo',
                        detalle:
                            'El colaborador tiene que adjuntar un documento '
                            'al pedirla.',
                        valor: _requiereDocumento,
                        onCambio: habilitado
                            ? (v) => _cambiar(() => _requiereDocumento = v)
                            : null,
                      ),
                      _Interruptor(
                        titulo: 'Activo',
                        detalle: _activo
                            ? 'Los colaboradores pueden elegirlo.'
                            : 'Los colaboradores ya no lo ven al pedir una '
                                  'ausencia.',
                        valor: _activo,
                        onCambio: habilitado
                            ? (v) => _cambiar(() => _activo = v)
                            : null,
                      ),
                    ],
                  ),
                  if (_errorGuardado != null) ...[
                    const SizedBox(height: 12),
                    _AvisoError(texto: _errorGuardado!),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    // Apagado mientras no haya nada que guardar.
                    onPressed: _guardando || !_hayCambios ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Los códigos se escriben en mayúsculas, como VAC o MED.
final _mayusculas = TextInputFormatter.withFunction(
  (_, nuevo) => nuevo.copyWith(text: nuevo.text.toUpperCase()),
);

/// Tarjeta blanca con un título pequeño: "Datos", "Condiciones".
///
/// Es un Material y no un Container con color: los interruptores pintan su
/// fondo y su onda en el Material más cercano, y un color intermedio los
/// taparía.
class _Seccion extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Seccion({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.carta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        side: const BorderSide(color: AppColors.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.tinta2,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Un sí/no del tipo, con una línea que explica qué significa.
class _Interruptor extends StatelessWidget {
  final String titulo;
  final String detalle;
  final bool valor;
  final ValueChanged<bool>? onCambio;

  const _Interruptor({
    required this.titulo,
    required this.detalle,
    required this.valor,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: valor,
      onChanged: onCambio,
      contentPadding: EdgeInsets.zero,
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 14, color: AppColors.tinta),
      ),
      subtitle: Text(
        detalle,
        style: const TextStyle(fontSize: 12, color: AppColors.tinta2),
      ),
    );
  }
}

/// Estado 4: el backend no aceptó el cambio o no hubo conexión.
class _AvisoError extends StatelessWidget {
  final String texto;

  const _AvisoError({required this.texto});

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
          const Icon(Icons.cloud_off, size: 18, color: AppColors.rojo700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.rojo700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
