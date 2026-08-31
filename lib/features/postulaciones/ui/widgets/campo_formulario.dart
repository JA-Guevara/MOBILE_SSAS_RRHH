import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Campo de texto con la etiqueta encima, como en la maqueta:
/// "Nombres *" y debajo la caja blanca con borde AppColors.borde.
class CampoFormulario extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final bool obligatorio;
  final String? ayuda;
  final TextInputType? tipoTeclado;
  final TextInputAction accionTeclado;
  final List<TextInputFormatter>? formateadores;
  final String? Function(String?)? validador;
  final ValueChanged<String>? onCambio;
  final bool habilitado;

  const CampoFormulario({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.obligatorio = false,
    this.ayuda,
    this.tipoTeclado,
    this.accionTeclado = TextInputAction.next,
    this.formateadores,
    this.validador,
    this.onCambio,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EtiquetaCampo(
            texto: etiqueta,
            obligatorio: obligatorio,
            ayuda: ayuda,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: habilitado,
            keyboardType: tipoTeclado,
            textInputAction: accionTeclado,
            inputFormatters: formateadores,
            validator: validador,
            onChanged: onCambio,
            style: const TextStyle(fontSize: 14, color: AppColors.tinta),
            decoration: decoracionCampo(),
          ),
        ],
      ),
    );
  }
}

/// Desplegable con el mismo aspecto que [CampoFormulario].
class CampoSeleccion extends StatelessWidget {
  final String etiqueta;
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onCambio;
  final String textoVacio;
  final bool habilitado;

  const CampoSeleccion({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onCambio,
    this.textoVacio = 'Sin especificar',
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EtiquetaCampo(texto: etiqueta),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            initialValue: valor,
            isExpanded: true,
            onChanged: habilitado ? onCambio : null,
            style: const TextStyle(fontSize: 14, color: AppColors.tinta),
            decoration: decoracionCampo(),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  textoVacio,
                  style: const TextStyle(color: AppColors.tinta2),
                ),
              ),
              ...opciones.map(
                (o) => DropdownMenuItem<String?>(value: o, child: Text(o)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Etiqueta del campo: texto, asterisco rojo si es obligatorio y una ayuda
/// pequeña opcional ("PDF/DOCX · máx 5 MB").
class EtiquetaCampo extends StatelessWidget {
  final String texto;
  final bool obligatorio;
  final String? ayuda;

  const EtiquetaCampo({
    super.key,
    required this.texto,
    this.obligatorio = false,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.tinta,
          ),
        ),
        if (obligatorio)
          const Text(
            ' *',
            style: TextStyle(fontSize: 12.5, color: AppColors.rojo700),
          ),
        if (ayuda != null) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              ayuda!,
              style: const TextStyle(fontSize: 11, color: AppColors.tinta2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Caja blanca con borde de la guía, compartida por texto y desplegable.
InputDecoration decoracionCampo() {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.carta,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: _borde(AppColors.borde),
    enabledBorder: _borde(AppColors.borde),
    disabledBorder: _borde(AppColors.borde),
    focusedBorder: _borde(AppColors.verde600, ancho: 1.6),
    errorBorder: _borde(AppColors.rojo700),
    focusedErrorBorder: _borde(AppColors.rojo700, ancho: 1.6),
    errorStyle: const TextStyle(fontSize: 11.5, color: AppColors.rojo700),
  );
}

OutlineInputBorder _borde(Color color, {double ancho = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.boton),
    borderSide: BorderSide(color: color, width: ancho),
  );
}
