import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/ui/widgets/campo_formulario.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/ui/seguimiento_page.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Puerta de entrada a T2-18: el candidato escribe el código de seguimiento
/// que recibió al postular (T1-20) y pasa a ver su línea de tiempo.
///
/// La maqueta de la guía solo dibuja la pantalla de resultado, así que esta
/// se construyó con los mismos componentes del formulario de T1-20.
///
/// Ubicación:  lib/features/seguimiento/ui/consulta_codigo_page.dart
class ConsultaCodigoPage extends StatefulWidget {
  final SeguimientoService service;

  /// Código con el que arranca el campo. Útil para encadenar desde T1-20.
  final String? codigoInicial;

  const ConsultaCodigoPage({
    super.key,
    required this.service,
    this.codigoInicial,
  });

  @override
  State<ConsultaCodigoPage> createState() => _ConsultaCodigoPageState();
}

class _ConsultaCodigoPageState extends State<ConsultaCodigoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo = TextEditingController(
    text: widget.codigoInicial ?? '',
  );

  var _autovalidar = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  String? _validarCodigo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu código de seguimiento.';
    if (v.length > 40) {
      return 'El código es demasiado largo.';
    }
    return null;
  }

  void _consultar() {
    setState(() => _autovalidar = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeguimientoPage(
          codigo: _codigo.text.trim().toUpperCase(),
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
                          'Consulta el estado de tu postulación con el código '
                          'que te dimos al postular.',
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
                          ayuda: 'ej. POST-A1B2C3D4',
                          accionTeclado: TextInputAction.done,
                          formateadores: [
                            // El código siempre va en mayúsculas: se convierte
                            // mientras se escribe para no rechazarlo por eso.
                            _AMayusculas(),
                            LengthLimitingTextInputFormatter(40),
                          ],
                          validador: _validarCodigo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _consultar,
                    child: const Text('Ver mi postulación'),
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
            'Mi postulación',
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
