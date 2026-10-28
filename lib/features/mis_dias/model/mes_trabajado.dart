import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';

/// Cómo quedó un día marcado.
enum EstadoDia {
  /// Marcó entrada y salida.
  completo,

  /// Es hoy y todavía no marcó la salida: no es un olvido, sigue trabajando.
  enJornada,

  /// Un día pasado con entrada y sin salida: hay que avisar a RR. HH.
  sinSalida,
}

/// Los días trabajados de un mes y el saldo de vacaciones (T3-21 · HU-15).
///
/// No define claves del API: cada día es una fila de la tabla "asistencia"
/// leída con el modelo de T3-18, y el saldo es el de T3-19. Aquí solo se
/// suma y se resume.
class MesTrabajado {
  /// Primer día del mes que se muestra.
  final DateTime mes;

  /// Las marcas del mes, de la más reciente a la más antigua.
  final List<Asistencia> dias;

  final SaldoVacacion? saldo;

  const MesTrabajado({required this.mes, required this.dias, this.saldo});

  /// Días con marca de entrada, incluido hoy si ya marcó.
  int get diasTrabajados => dias.where((d) => d.tieneEntrada).length;

  /// Suma de horas_trabajadas. Los días abiertos todavía no tienen horas:
  /// el backend las calcula al marcar la salida.
  double get horasTrabajadas =>
      dias.fold(0, (total, d) => total + (d.horasTrabajadas ?? 0));

  double get horasExtra =>
      dias.fold(0, (total, d) => total + (d.horasExtra ?? 0));

  int get diasConRetraso =>
      dias.where((d) => (d.minutosRetraso ?? 0) > 0).length;

  int get minutosRetraso =>
      dias.fold(0, (total, d) => total + (d.minutosRetraso ?? 0));

  /// Días pasados con entrada y sin salida.
  int sinSalida(DateTime hoy) =>
      dias.where((d) => estadoDe(d, hoy) == EstadoDia.sinSalida).length;

  static EstadoDia estadoDe(Asistencia dia, DateTime hoy) {
    if (dia.diaCompleto) return EstadoDia.completo;
    final fecha = dia.fecha;
    final esHoy =
        fecha != null &&
        fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
    return esHoy ? EstadoDia.enJornada : EstadoDia.sinSalida;
  }

  // ------------------------------------------------------------- para mostrar

  static const _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  /// "Octubre 2026".
  static String etiquetaMes(DateTime mes) =>
      '${_meses[mes.month - 1]} ${mes.year}';

  /// "2026-10": el parámetro ?mes= de la ruta.
  static String parametroMes(DateTime mes) =>
      '${mes.year}-${mes.month.toString().padLeft(2, '0')}';

  /// "Mié 28/10".
  static String etiquetaDia(DateTime fecha) =>
      '${_dias[fecha.weekday - 1]} '
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}';

  /// 9.15 -> "9.15 h", 137.5 -> "137.5 h", 8.0 -> "8 h". Mismo formato
  /// decimal que la pantalla de asistencia de T3-18.
  static String horas(double valor) {
    var texto = valor.toStringAsFixed(2);
    if (texto.contains('.')) {
      texto = texto.replaceFirst(RegExp(r'0+$'), '');
      if (texto.endsWith('.')) texto = texto.substring(0, texto.length - 1);
    }
    return '$texto h';
  }
}
