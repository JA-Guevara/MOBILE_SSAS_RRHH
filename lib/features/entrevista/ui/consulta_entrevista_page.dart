import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/ui/entrevista_page.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Puerta de entrada a T2-19: el candidato escribe su código de seguimiento
/// y pasa a ver los datos de su entrevista para confirmar asistencia.
///
/// Se construyó con los mismos componentes que ConsultaCodigoPage (T2-18).
///
/// Ubicación:  lib/features/entrevista/ui/consulta_entrevista_page.dart
class ConsultaEntrevistaPage extends StatefulWidget {
  final EntrevistaService service;

  /// Código con el que arranca el campo. Útil para las capturas.
  final String? codigoInicial;

  const ConsultaEntrevistaPage({
    super.key,
    required this.service,
    this.codigoInicial,
  });

  @override
  State<ConsultaEntrevistaPage> createState() => _ConsultaEntrevistaPageState();
}

class _ConsultaEntrevistaPageState extends State<ConsultaEntrevistaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo = TextEditingController(
    text: widget.codigoInicial ?? '',
  );

  /// Formato REAL del backend: "POST-" + 8 caracteres en mayúscula
  /// (crear_postulacion_publica.py en rrhh-api). Ej. POST-8F4K2A1C.
  static final _formato = RegExp(r'^POST-[A-Z0-9]{8}$');

  var _autovalidar = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  String? _validarCodigo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu código de seguimiento.';
    if (!_formato.hasMatch(v)) {
      return 'El código se ve así: POST-8F4K2A1C.';
    }
    return null;
  }

  void _consultar() {
    setState(() => _autovalidar = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntrevistaPage(
          codigo: _codigo.text.trim(),
          service: widget.service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidar
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: ListView(
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
                        const Text(
                          'Revisa la fecha y el lugar de tu entrevista y '
                          'confirma tu asistencia con el código que te dimos '
                          'al postular.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.tinta2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CampoFormulario(
                          etiqueta: 'Código de seguimiento',
                          controller: _codigo,
                          obligatorio: true,
                          ayuda: 'formato POST-8F4K2A1C',
                          accionTeclado: TextInputAction.done,
                          formateadores: [
                            _AMayusculas(),
                            LengthLimitingTextInputFormatter(13),
                          ],
                          validador: _validarCodigo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _consultar,
                    child: const Text('Ver mi entrevista'),
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

/// Pasa a mayúsculas lo que se escribe, sin mover el cursor de sitio.
class _AMayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    return nuevo.copyWith(text: nuevo.text.toUpperCase());
  }
}

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
            'SSAH · Portal de empleos',
            style: TextStyle(color: Color(0xFF8FB49C), fontSize: 12),
          ),
          SizedBox(height: 6),
          Text(
            'Mi entrevista',
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
