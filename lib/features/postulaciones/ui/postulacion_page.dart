import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/postulante.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/resultado_postulacion.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/postulacion_exitosa.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/selector_cv.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Estados de la pantalla, igual que en vacantes.
enum _Estado {
  /// Formulario en pantalla: vacío al entrar, con datos mientras se escribe.
  formulario,

  /// Multipart en camino: todo bloqueado.
  enviando,

  /// El backend aceptó: se muestra el código de seguimiento.
  exito,

  /// Falló el envío: mensaje + reintentar.
  error,
}

/// Pantalla de postulación al portal público de empleos (T1-20).
///
/// Maneja los estados que necesitas para la evidencia:
///   1. Formulario vacío -> al entrar                (captura "vacía")
///   2. Con datos        -> lleno y enviado con éxito, muestra el código
///                          de seguimiento           (captura "con datos")
///   3. Enviando         -> botón bloqueado + spinner
///   4. Error            -> mensaje + reintentar     (captura "con error")
///
/// La validación de este archivo es SOLO PARA UX: evita viajes inútiles al
/// servidor. La autoridad es el backend; si rechaza algún campo (422) sus
/// mensajes se pintan debajo del campo correspondiente.
class PostulacionPage extends StatefulWidget {
  final String slug;
  final String empresaNombre;
  final String vacanteId;
  final String vacanteTitulo;
  final PostulacionesService service;

  const PostulacionPage({
    super.key,
    required this.slug,
    required this.empresaNombre,
    required this.vacanteId,
    required this.vacanteTitulo,
    required this.service,
  });

  @override
  State<PostulacionPage> createState() => _PostulacionPageState();
}

class _PostulacionPageState extends State<PostulacionPage> {
  final _formKey = GlobalKey<FormState>();

  // Un controlador por campo de la tabla "postulante".
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _ci = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _ciudad = TextEditingController();
  final _aniosExperiencia = TextEditingController();
  final _linkedin = TextEditingController();

  /// >>> VERIFICA estos valores contra el backend antes de la demo. <<<
  static const _nivelesEducativos = [
    'Secundaria',
    'Técnico',
    'Universitario en curso',
    'Licenciatura',
    'Maestría',
    'Doctorado',
  ];
  String? _nivelEducativo;

  CvAdjunto? _cv;

  var _estado = _Estado.formulario;
  ResultadoPostulacion? _resultado;
  String _mensajeError = '';

  /// Errores que devolvió el backend, por nombre de campo del API
  /// ("email", "ci", ...). Se limpian en cuanto el usuario corrige el campo.
  Map<String, String> _erroresBackend = {};

  /// Solo se validan los campos mientras se escribe DESPUÉS del primer envío,
  /// para no llenar de rojo un formulario que el usuario recién abrió.
  var _autovalidar = false;

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _ci.dispose();
    _email.dispose();
    _telefono.dispose();
    _ciudad.dispose();
    _aniosExperiencia.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- validación

  String? _requerido(String? valor, String queFalta) {
    if (valor == null || valor.trim().isEmpty) return 'Ingresa $queFalta.';
    if (valor.trim().length < 2) return 'Ingresa $queFalta completo.';
    return null;
  }

  String? _validarEmail(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo.';
    // Comprobación deliberadamente simple: el correo de verdad se valida
    // cuando llegue el mensaje. Aquí solo se atrapan errores de tipeo.
    final formato = RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$');
    if (!formato.hasMatch(v)) return 'El correo no tiene un formato válido.';
    return null;
  }

  String? _validarAnios(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return null; // opcional
    final n = int.tryParse(v);
    if (n == null) return 'Usa solo números.';
    if (n > 60) return 'Revisa los años de experiencia.';
    return null;
  }

  String? _validarLinkedin(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return null; // opcional
    if (!v.contains('linkedin.com')) {
      return 'Pega la dirección completa de tu perfil de LinkedIn.';
    }
    return null;
  }

  /// Combina la validación local con lo que rechazó el backend.
  String? Function(String?) _conBackend(
    String campo,
    String? Function(String?) local,
  ) {
    return (valor) => _erroresBackend[campo] ?? local(valor);
  }

  /// El usuario corrigió el campo: el reclamo del backend ya no aplica.
  void _limpiarErrorBackend(String campo) {
    if (!_erroresBackend.containsKey(campo)) return;
    setState(() => _erroresBackend = {..._erroresBackend}..remove(campo));
  }

  // -------------------------------------------------------------------- envío

  Future<void> _enviar() async {
    setState(() => _autovalidar = true);

    final formOk = _formKey.currentState?.validate() ?? false;
    // El CV no vive dentro del Form, así que se comprueba aparte.
    final cv = _cv;
    if (!formOk || cv == null) {
      setState(() {});
      return;
    }

    await _despachar(
      Postulante(
        nombres: _nombres.text,
        apellidos: _apellidos.text,
        email: _email.text,
        ci: _ci.text,
        telefono: _telefono.text,
        ciudad: _ciudad.text,
        nivelEducativo: _nivelEducativo,
        aniosExperiencia: int.tryParse(_aniosExperiencia.text.trim()),
        linkedin: _linkedin.text,
      ),
      cv,
    );
  }

  /// Manda el multipart. Se guarda lo enviado en [_ultimoEnvio] para que
  /// "Reintentar" desde la pantalla de error no dependa del formulario,
  /// que en ese momento ya no está en el árbol de widgets.
  (Postulante, CvAdjunto)? _ultimoEnvio;

  Future<void> _reintentar() async {
    final ultimo = _ultimoEnvio;
    if (ultimo == null) {
      setState(() => _estado = _Estado.formulario);
      return;
    }
    await _despachar(ultimo.$1, ultimo.$2);
  }

  Future<void> _despachar(Postulante postulante, CvAdjunto cv) async {
    setState(() {
      _ultimoEnvio = (postulante, cv);
      _estado = _Estado.enviando;
      _erroresBackend = {};
    });

    try {
      final resultado = await widget.service.postular(
        slug: widget.slug,
        vacanteId: widget.vacanteId,
        postulante: postulante,
        cv: cv,
      );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _estado = _Estado.exito;
      });
    } on PostulacionException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.erroresPorCampo.isNotEmpty) {
          // El backend señaló campos concretos: se vuelve al formulario
          // con esos mensajes puestos donde corresponde.
          _erroresBackend = e.erroresPorCampo;
          _estado = _Estado.formulario;
        } else {
          _mensajeError = e.message;
          _estado = _Estado.error;
        }
      });
      if (_estado == _Estado.formulario) _formKey.currentState?.validate();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError =
            'No se pudo enviar la postulación. '
            'Revisa tu conexión e inténtalo de nuevo.\n($e)';
        _estado = _Estado.error;
      });
    }
  }

  // --------------------------------------------------------------------- vista

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Cabecera(
            empresaNombre: widget.empresaNombre,
            titulo: _estado == _Estado.exito ? 'Listo' : 'Tus datos',
            onVolver: _estado == _Estado.enviando
                ? null
                : () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: _cuerpo()),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    return switch (_estado) {
      _Estado.exito => PostulacionExitosa(
        resultado: _resultado!,
        vacanteTitulo: widget.vacanteTitulo,
        onVolver: () => Navigator.of(context).maybePop(),
      ),
      _Estado.error => _EstadoError(
        mensaje: _mensajeError,
        onReintentar: _reintentar,
        onVolverAlFormulario: () =>
            setState(() => _estado = _Estado.formulario),
      ),
      _ => _formulario(),
    };
  }

  Widget _formulario() {
    final enviando = _estado == _Estado.enviando;
    final habilitado = !enviando;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidar
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TarjetaVacante(titulo: widget.vacanteTitulo),
          const SizedBox(height: 12),
          if (_erroresBackend.isNotEmpty) ...[
            const _AvisoBackend(),
            const SizedBox(height: 12),
          ],
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
                CampoFormulario(
                  etiqueta: 'Nombres',
                  controller: _nombres,
                  obligatorio: true,
                  habilitado: habilitado,
                  tipoTeclado: TextInputType.name,
                  validador: _conBackend(
                    'nombres',
                    (v) => _requerido(v, 'tus nombres'),
                  ),
                  onCambio: (_) => _limpiarErrorBackend('nombres'),
                ),
                CampoFormulario(
                  etiqueta: 'Apellidos',
                  controller: _apellidos,
                  obligatorio: true,
                  habilitado: habilitado,
                  tipoTeclado: TextInputType.name,
                  validador: _conBackend(
                    'apellidos',
                    (v) => _requerido(v, 'tus apellidos'),
                  ),
                  onCambio: (_) => _limpiarErrorBackend('apellidos'),
                ),
                CampoFormulario(
                  etiqueta: 'Correo',
                  controller: _email,
                  obligatorio: true,
                  habilitado: habilitado,
                  tipoTeclado: TextInputType.emailAddress,
                  validador: _conBackend('email', _validarEmail),
                  onCambio: (_) => _limpiarErrorBackend('email'),
                ),
                CampoFormulario(
                  etiqueta: 'CI',
                  controller: _ci,
                  habilitado: habilitado,
                  tipoTeclado: TextInputType.text,
                  validador: _conBackend('ci', (_) => null),
                  onCambio: (_) => _limpiarErrorBackend('ci'),
                ),
                CampoFormulario(
                  etiqueta: 'Teléfono',
                  controller: _telefono,
                  habilitado: habilitado,
                  tipoTeclado: TextInputType.phone,
                  formateadores: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                  ],
                  validador: _conBackend('telefono', (_) => null),
                  onCambio: (_) => _limpiarErrorBackend('telefono'),
                ),
                CampoFormulario(
                  etiqueta: 'Ciudad',
                  controller: _ciudad,
                  habilitado: habilitado,
                  validador: _conBackend('ciudad', (_) => null),
                  onCambio: (_) => _limpiarErrorBackend('ciudad'),
                ),
                CampoSeleccion(
                  etiqueta: 'Nivel educativo',
                  valor: _nivelEducativo,
                  opciones: _nivelesEducativos,
                  habilitado: habilitado,
                  onCambio: (v) => setState(() => _nivelEducativo = v),
                ),
                CampoFormulario(
                  etiqueta: 'Años de experiencia',
                  controller: _aniosExperiencia,
                  habilitado: habilitado,
                  tipoTeclado: TextInputType.number,
                  formateadores: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validador: _conBackend('anios_experiencia', _validarAnios),
                  onCambio: (_) => _limpiarErrorBackend('anios_experiencia'),
                ),
                CampoFormulario(
                  etiqueta: 'LinkedIn',
                  controller: _linkedin,
                  ayuda: 'opcional',
                  habilitado: habilitado,
                  tipoTeclado: TextInputType.url,
                  accionTeclado: TextInputAction.done,
                  validador: _conBackend('linkedin', _validarLinkedin),
                  onCambio: (_) => _limpiarErrorBackend('linkedin'),
                ),
                SelectorCv(
                  cv: _cv,
                  habilitado: habilitado,
                  // Solo se reclama el CV después de intentar enviar.
                  error: _autovalidar && _cv == null
                      ? 'Adjunta tu hoja de vida para postular.'
                      : _erroresBackend['cv'],
                  onCambio: (cv) => setState(() => _cv = cv),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: enviando ? null : _enviar,
            child: enviando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar postulación'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Al enviar aceptas que la empresa use tus datos para este '
            'proceso de selección.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.tinta2),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía, con el botón de volver.
class _Cabecera extends StatelessWidget {
  final String empresaNombre;
  final String titulo;
  final VoidCallback? onVolver;

  const _Cabecera({
    required this.empresaNombre,
    required this.titulo,
    required this.onVolver,
  });

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
            onPressed: onVolver,
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SSAH · $empresaNombre',
                  style: const TextStyle(
                    color: Color(0xFF8FB49C),
                    fontSize: 12,
                  ),
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

/// Recuerda a qué vacante se está postulando.
class _TarjetaVacante extends StatelessWidget {
  final String titulo;

  const _TarjetaVacante({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        border: Border.all(color: AppColors.ambar100),
      ),
      child: Row(
        children: [
          const Icon(Icons.work_outline, size: 18, color: AppColors.ambar700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Postulas a',
                  style: TextStyle(fontSize: 11, color: AppColors.tinta2),
                ),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    color: AppColors.tinta,
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

/// Aviso de que el rechazo vino del servidor, no del formulario.
class _AvisoBackend extends StatelessWidget {
  const _AvisoBackend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rojo100,
        borderRadius: BorderRadius.circular(AppRadii.boton),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: AppColors.rojo700),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'El servidor rechazó algunos datos. Revisa los campos marcados.',
              style: TextStyle(fontSize: 12.5, color: AppColors.rojo700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado 4: no se pudo enviar.
class _EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  final VoidCallback onVolverAlFormulario;

  const _EstadoError({
    required this.mensaje,
    required this.onReintentar,
    required this.onVolverAlFormulario,
  });

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
            TextButton(
              onPressed: onVolverAlFormulario,
              style: TextButton.styleFrom(foregroundColor: AppColors.verde600),
              child: const Text('Volver al formulario'),
            ),
          ],
        ),
      ),
    );
  }
}
