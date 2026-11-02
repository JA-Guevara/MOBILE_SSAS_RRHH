import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// La marca de asistencia de un día (T3-18 · HU-15 · CU-23).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
///
/// Los 15 campos son los de la tabla "asistencia" del diagrama oficial:
///   id, empleado_id, fecha, hora_entrada, hora_salida,
///   latitud_entrada, longitud_entrada, latitud_salida, longitud_salida,
///   horas_trabajadas, horas_extra, minutos_retraso, origen, estado,
///   observacion
class Asistencia {
  final String id;
  final String? empleadoId;
  final DateTime? fecha;

  /// >>> VERIFICA contra /docs <<<  Se guardan tal cual llegan porque una
  /// columna TIME ("08:03:00") no es una fecha válida para DateTime.parse.
  /// El formateo a "08:03" lo hace [_soloHoraMinuto], que aguanta tanto
  /// "08:03:00" como un ISO completo "2026-08-29T08:03:00".
  final String? horaEntrada;
  final String? horaSalida;

  final double? latitudEntrada;
  final double? longitudEntrada;
  final double? latitudSalida;
  final double? longitudSalida;

  final double? horasTrabajadas;
  final double? horasExtra;
  final int? minutosRetraso;

  /// De dónde vino la marca. La app manda [origenMovil].
  final String? origen;

  final String? estado;
  final String? observacion;

  /// Valor que la app envía en "origen" al marcar desde el teléfono.
  /// Es el literal del enum de T3-04 (APP_MOVIL / WEB / MANUAL).
  /// >>> VERIFICA contra /docs <<<  Si cambia, se cambia aquí y en ningún
  /// otro sitio.
  static const origenMovil = 'APP_MOVIL';

  const Asistencia({
    required this.id,
    this.empleadoId,
    this.fecha,
    this.horaEntrada,
    this.horaSalida,
    this.latitudEntrada,
    this.longitudEntrada,
    this.latitudSalida,
    this.longitudSalida,
    this.horasTrabajadas,
    this.horasExtra,
    this.minutosRetraso,
    this.origen,
    this.estado,
    this.observacion,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  /// Lee SOLO las columnas de la tabla "asistencia" del diagrama.
  factory Asistencia.fromJson(Map<String, dynamic> cuerpo) {
    return Asistencia(
      id: leerId(cuerpo['id']) ?? '',
      empleadoId: leerId(cuerpo['empleado_id']),
      fecha: _parseFecha(cuerpo['fecha']),
      horaEntrada: _texto(cuerpo['hora_entrada']),
      horaSalida: _texto(cuerpo['hora_salida']),
      latitudEntrada: (cuerpo['latitud_entrada'] as num?)?.toDouble(),
      longitudEntrada: (cuerpo['longitud_entrada'] as num?)?.toDouble(),
      latitudSalida: (cuerpo['latitud_salida'] as num?)?.toDouble(),
      longitudSalida: (cuerpo['longitud_salida'] as num?)?.toDouble(),
      horasTrabajadas: (cuerpo['horas_trabajadas'] as num?)?.toDouble(),
      horasExtra: (cuerpo['horas_extra'] as num?)?.toDouble(),
      minutosRetraso: (cuerpo['minutos_retraso'] as num?)?.toInt(),
      origen: cuerpo['origen'] as String?,
      estado: cuerpo['estado'] as String?,
      observacion: cuerpo['observacion'] as String?,
    );
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Una hora vacía en el backend puede llegar como null o como "". Las dos
  /// significan "todavía no marcó", así que se normalizan a null.
  static String? _texto(dynamic valor) {
    if (valor == null) return null;
    final s = valor.toString().trim();
    return s.isEmpty ? null : s;
  }

  // ------------------------------------------------------------ estado del día

  bool get tieneEntrada => horaEntrada != null;
  bool get tieneSalida => horaSalida != null;

  /// El día ya está cerrado: no queda nada por marcar.
  bool get diaCompleto => tieneEntrada && tieneSalida;

  /// Qué toca marcar ahora. Es lo que decide el texto del botón.
  MarcaPendiente get pendiente {
    if (!tieneEntrada) return MarcaPendiente.entrada;
    if (!tieneSalida) return MarcaPendiente.salida;
    return MarcaPendiente.ninguna;
  }

  // ------------------------------------------------------------- para mostrar

  /// "08:03" o "—:—" si todavía no marcó.
  String get entradaCorta => _soloHoraMinuto(horaEntrada);
  String get salidaCorta => _soloHoraMinuto(horaSalida);

  /// "08:03 a 17:12", como en la maqueta.
  String get resumenHoras => '$entradaCorta a $salidaCorta';

  /// Texto que se muestra cuando no hay hora.
  static const sinHora = '—:—';

  /// Saca "HH:MM" de "08:03:00", de "2026-08-29T08:03:00" o de "08:03".
  /// Si no reconoce el formato devuelve el valor tal cual, para no ocultar
  /// lo que mandó el backend.
  static String _soloHoraMinuto(String? valor) {
    if (valor == null) return sinHora;

    final conT = valor.contains('T') ? valor.split('T').last : valor;
    final partes = conT.split(':');
    if (partes.length < 2) return valor;

    final hh = partes[0].padLeft(2, '0');
    final mm = partes[1].substring(0, mm2(partes[1])).padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Los minutos pueden venir como "03" o como "03.5"; se corta en 2 dígitos.
  static int mm2(String minutos) => minutos.length < 2 ? minutos.length : 2;
}

/// Qué acción ofrece el botón grande de la pantalla.
enum MarcaPendiente { entrada, salida, ninguna }
