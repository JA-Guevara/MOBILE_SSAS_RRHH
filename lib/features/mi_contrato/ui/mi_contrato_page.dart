import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/equipo/model/contrato.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/model/historial_contratos.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Mi contrato vigente (T3-28 · HU-11 · CU-21). Solo lectura.
///
/// Arriba, el contrato en vigor con todos sus datos; debajo, las versiones
/// anteriores con el motivo de cada cambio (renovación, ascenso...).
///
/// Estados para la evidencia:
///   1. Cargando             -> spinner
///   2. Vigente + historial  -> captura "con datos"
///   3. Primer contrato      -> vigente sin versiones anteriores
///   4. Sin vigente          -> aviso + historial
///   5. Sin contratos        -> mensaje (captura "vacía")
///   6. Error                -> mensaje + reintentar ("error" y "sesión")
///
/// Ubicación:  lib/features/mi_contrato/ui/mi_contrato_page.dart
class MiContratoPage extends StatefulWidget {
  final MiContratoService service;

  const MiContratoPage({super.key, required this.service});

  @override
  State<MiContratoPage> createState() => _MiContratoPageState();
}

class _MiContratoPageState extends State<MiContratoPage> {
  late Future<HistorialContratos> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.historial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          Expanded(
            child: FutureBuilder<HistorialContratos>(
              future: _futuro,
              builder: (context, snap) {
                // Estado 1: cargando
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.verde600),
                  );
                }
                // Estado 6: error
                if (snap.hasError) {
                  return _EstadoError(
                    mensaje: mensajeDeErrorMiContrato(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                final historial = snap.data!;
                // Estado 5: ningún contrato
                if (historial.estaVacio) return const _EstadoVacio();
                // Estados 2, 3 y 4
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: _Contenido(historial: historial),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía: "Colaborador / Mi contrato".
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
                  'Mi contrato',
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

/// Estados 2, 3 y 4: el vigente arriba y el historial debajo.
class _Contenido extends StatelessWidget {
  final HistorialContratos historial;

  const _Contenido({required this.historial});

  @override
  Widget build(BuildContext context) {
    final vigente = historial.vigente;
    final anteriores = historial.anteriores;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (vigente != null)
          _TarjetaVigente(contrato: vigente, cargo: historial.cargoDe(vigente))
        else
          // Estado 4: ya no tiene contrato en vigor.
          const _Aviso(
            texto:
                'No tienes un contrato vigente. Si crees que es un error, '
                'consulta con Recursos Humanos.',
          ),
        const SizedBox(height: 22),
        Text(
          anteriores.isEmpty
              ? 'Versiones anteriores'
              : 'Versiones anteriores · ${anteriores.length}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.tinta2,
          ),
        ),
        const SizedBox(height: 10),
        if (anteriores.isEmpty)
          // Estado 3: es su primer contrato.
          const Text(
            'Es tu primer contrato: todavía no tiene versiones anteriores.',
            style: TextStyle(fontSize: 13, color: AppColors.tinta2),
          )
        else
          for (final c in anteriores)
            _VersionAnterior(contrato: c, cargo: historial.cargoDe(c)),
        const SizedBox(height: 16),
        const Text(
          'Esta pantalla es solo de consulta. Para cualquier cambio en tu '
          'contrato, habla con Recursos Humanos.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.tinta2),
        ),
      ],
    );
  }
}

/// El contrato en vigor, con todos los campos de la tarea.
class _TarjetaVigente extends StatelessWidget {
  final Contrato contrato;
  final String? cargo;

  const _TarjetaVigente({required this.contrato, required this.cargo});

  @override
  Widget build(BuildContext context) {
    final c = contrato;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cargo ?? 'Contrato vigente',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        color: AppColors.tinta,
                      ),
                    ),
                    if (c.numeroContrato != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'N.º ${c.numeroContrato}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.tinta2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const _Chip(
                texto: 'Vigente',
                fondo: AppColors.verde100,
                color: AppColors.verde600,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // El salario, destacado: es lo primero que el colaborador busca.
          Text(
            HistorialContratos.salario(c),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.verde600,
            ),
          ),
          const Text(
            'salario básico mensual',
            style: TextStyle(fontSize: 12, color: AppColors.tinta2),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borde),
          const SizedBox(height: 12),
          _Dato(
            etiqueta: 'Tipo de contrato',
            valor: HistorialContratos.legible(c.tipoContrato),
          ),
          _Dato(
            etiqueta: 'Modalidad',
            valor: HistorialContratos.legible(c.modalidad),
          ),
          _Dato(
            etiqueta: 'Jornada',
            valor: HistorialContratos.legible(c.jornada),
          ),
          _Dato(
            etiqueta: 'Desde',
            valor: HistorialContratos.fecha(c.fechaInicio),
          ),
          _Dato(etiqueta: 'Hasta', valor: HistorialContratos.hasta(c)),
          if (c.motivoCambio != null)
            _Dato(etiqueta: 'Último cambio', valor: c.motivoCambio!),
        ],
      ),
    );
  }
}

/// Una versión cerrada: periodo, salario, tipo y por qué se cambió.
class _VersionAnterior extends StatelessWidget {
  final Contrato contrato;
  final String? cargo;

  const _VersionAnterior({required this.contrato, required this.cargo});

  @override
  Widget build(BuildContext context) {
    final c = contrato;
    final detalle = [
      HistorialContratos.salario(c),
      HistorialContratos.legible(c.tipoContrato),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                  cargo ?? c.numeroContrato ?? 'Contrato',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tinta,
                  ),
                ),
              ),
              _Chip(
                texto: HistorialContratos.legible(c.estado),
                fondo: AppColors.mentaBg,
                color: AppColors.tinta2,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            HistorialContratos.periodo(c),
            style: const TextStyle(fontSize: 12.5, color: AppColors.tinta2),
          ),
          const SizedBox(height: 2),
          Text(
            detalle,
            style: const TextStyle(fontSize: 12.5, color: AppColors.tinta),
          ),
          const SizedBox(height: 4),
          Text(
            c.motivoCambio ?? 'Contrato inicial',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.tinta2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila "etiqueta · valor" de la tarjeta vigente.
class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              etiqueta,
              style: const TextStyle(fontSize: 13, color: AppColors.tinta2),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.tinta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;

  const _Chip({required this.texto, required this.fondo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Aviso ámbar: algo que conviene saber, pero que no es un error.
class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ambar100,
        borderRadius: BorderRadius.circular(AppRadii.boton),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.ambar700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.ambar700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado 5: todavía no tiene ningún contrato registrado.
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
            Icon(Icons.description_outlined, size: 48, color: AppColors.tinta2),
            SizedBox(height: 12),
            Text(
              'Todavía no tienes un contrato registrado',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando Recursos Humanos lo registre, lo verás aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.tinta2, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado 6: no se pudo cargar.
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
