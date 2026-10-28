import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/tarjeta_saldo.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/data/mis_dias_service.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/model/mes_trabajado.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/ui/widgets/dia_trabajado_card.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Mis días trabajados y saldo de vacaciones (T3-21 · HU-15).
///
/// El colaborador ve su saldo de vacaciones, el resumen del mes (días,
/// horas, horas extra, retrasos) y cada día con su entrada y su salida.
/// Puede ir a meses anteriores; al futuro no, porque no hay nada que ver.
///
/// Maneja los estados de siempre:
///   1. Cargando        -> spinner
///   2. Con datos       -> saldo + resumen + días  (captura "con días")
///   3. Mes sin marcas  -> aviso dentro de la lista (captura "mes vacío")
///   4. Error           -> mensaje + reintentar    ("error" y "sesión")
///
/// Ubicación:  lib/features/mis_dias/ui/mis_dias_page.dart
class MisDiasPage extends StatefulWidget {
  final MisDiasService service;

  /// El "hoy" de la pantalla. Se inyecta para que las pruebas no dependan
  /// del día en que corren; en la app es DateTime.now.
  final DateTime Function()? reloj;

  const MisDiasPage({super.key, required this.service, this.reloj});

  @override
  State<MisDiasPage> createState() => _MisDiasPageState();
}

class _MisDiasPageState extends State<MisDiasPage> {
  late DateTime _mes;
  late Future<MesTrabajado> _futuro;

  DateTime get _hoy => DateUtils.dateOnly((widget.reloj ?? DateTime.now)());

  bool get _esMesActual => _mes.year == _hoy.year && _mes.month == _hoy.month;

  @override
  void initState() {
    super.initState();
    _mes = DateTime(_hoy.year, _hoy.month);
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futuro = widget.service.delMes(_mes);
    });
  }

  void _cambiarMes(int delta) {
    _mes = DateTime(_mes.year, _mes.month + delta);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Cabecera(),
          _SelectorMes(
            mes: _mes,
            onAnterior: () => _cambiarMes(-1),
            // No hay marcas en el futuro: el botón se apaga en el mes actual.
            onSiguiente: _esMesActual ? null : () => _cambiarMes(1),
          ),
          Expanded(
            child: FutureBuilder<MesTrabajado>(
              future: _futuro,
              builder: (context, snap) {
                // Estado 1: cargando
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.verde600),
                  );
                }
                // Estado 4: error
                if (snap.hasError) {
                  return _EstadoError(
                    mensaje: mensajeDeErrorMisDias(snap.error!),
                    onReintentar: _cargar,
                  );
                }
                // Estados 2 y 3
                return RefreshIndicator(
                  color: AppColors.verde600,
                  onRefresh: () async => _cargar(),
                  child: _Contenido(mes: snap.data!, hoy: _hoy),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera verde de la guía: "Colaborador / Mis días trabajados".
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
                  'Mis días trabajados',
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

/// "‹  Octubre 2026  ›".
class _SelectorMes extends StatelessWidget {
  final DateTime mes;
  final VoidCallback onAnterior;
  final VoidCallback? onSiguiente;

  const _SelectorMes({
    required this.mes,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.carta,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onAnterior,
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left, color: AppColors.verde600),
          ),
          Expanded(
            child: Text(
              MesTrabajado.etiquetaMes(mes),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.tinta,
              ),
            ),
          ),
          IconButton(
            onPressed: onSiguiente,
            tooltip: 'Mes siguiente',
            icon: Icon(
              Icons.chevron_right,
              color: onSiguiente == null ? AppColors.borde : AppColors.verde600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estados 2 y 3: saldo, resumen del mes y la lista de días.
class _Contenido extends StatelessWidget {
  final MesTrabajado mes;
  final DateTime hoy;

  const _Contenido({required this.mes, required this.hoy});

  @override
  Widget build(BuildContext context) {
    final saldo = mes.saldo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (saldo != null)
          TarjetaSaldo(saldo: saldo, diasSolicitados: null)
        else
          const _Aviso(
            texto: 'Todavía no tienes saldo de vacaciones asignado.',
            icono: Icons.info_outline,
          ),
        const SizedBox(height: 16),
        if (mes.dias.isEmpty)
          // Estado 3: no es un error, simplemente no hay marcas.
          _MesVacio(mes: mes.mes)
        else ...[
          _Resumen(mes: mes, hoy: hoy),
          const SizedBox(height: 16),
          for (final dia in mes.dias)
            DiaTrabajadoCard(dia: dia, estado: MesTrabajado.estadoDe(dia, hoy)),
        ],
      ],
    );
  }
}

/// Las tres cifras del mes y, debajo, lo que hay que notar.
class _Resumen extends StatelessWidget {
  final MesTrabajado mes;
  final DateTime hoy;

  const _Resumen({required this.mes, required this.hoy});

  @override
  Widget build(BuildContext context) {
    final sinSalida = mes.sinSalida(hoy);
    final conRetraso = mes.diasConRetraso;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carta,
        borderRadius: BorderRadius.circular(AppRadii.tarjeta),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Cifra(
                valor: '${mes.diasTrabajados}',
                etiqueta: mes.diasTrabajados == 1
                    ? 'día trabajado'
                    : 'días trabajados',
              ),
              _Cifra(
                valor: MesTrabajado.horas(mes.horasTrabajadas),
                etiqueta: 'trabajadas',
              ),
              _Cifra(
                valor: MesTrabajado.horas(mes.horasExtra),
                etiqueta: 'extra',
              ),
            ],
          ),
          if (conRetraso > 0) ...[
            const SizedBox(height: 12),
            Text(
              '${conRetraso == 1 ? '1 día' : '$conRetraso días'} con retraso '
              '· ${mes.minutosRetraso} min en total',
              style: const TextStyle(fontSize: 12.5, color: AppColors.tinta2),
            ),
          ],
          if (sinSalida > 0) ...[
            const SizedBox(height: 12),
            _Aviso(
              texto: sinSalida == 1
                  ? '1 día sin marca de salida. Avisa a Recursos Humanos para '
                        'corregirlo.'
                  : '$sinSalida días sin marca de salida. Avisa a Recursos '
                        'Humanos para corregirlos.',
              icono: Icons.warning_amber_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _Cifra({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              color: AppColors.verde600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppColors.tinta2),
          ),
        ],
      ),
    );
  }
}

/// Aviso ámbar: algo que conviene saber, pero que no es un error.
class _Aviso extends StatelessWidget {
  final String texto;
  final IconData icono;

  const _Aviso({required this.texto, required this.icono});

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
          Icon(icono, size: 18, color: AppColors.ambar700),
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

/// Estado 3: el mes no tiene marcas.
class _MesVacio extends StatelessWidget {
  final DateTime mes;

  const _MesVacio({required this.mes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 48,
            color: AppColors.tinta2,
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes marcas de asistencia en '
            '${MesTrabajado.etiquetaMes(mes).toLowerCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.tinta2, fontSize: 15),
          ),
        ],
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
