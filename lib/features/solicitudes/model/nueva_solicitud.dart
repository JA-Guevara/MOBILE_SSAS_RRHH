import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/model/documento_adjunto.dart';

/// Lo que el colaborador envía al pedir permiso o vacaciones (T3-19).
///
/// Columnas de "solicitud_ausencia" que pone el colaborador:
///   tipo_ausencia_id, fecha_inicio, fecha_fin, dias_solicitados, motivo,
///   y el archivo que el backend guarda como documento_url.
/// empleado_id NO va: el backend lo saca del token. aprobador_id, estado y
/// fecha_solicitud tampoco: los pone el backend.
class NuevaSolicitud {
  final TipoAusencia tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String motivo;
  final DocumentoAdjunto? documento;

  const NuevaSolicitud({
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    this.documento,
  });

  int get diasSolicitados => diasHabiles(fechaInicio, fechaFin);

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  /// Los campos de texto del multipart.
  Map<String, String> toFields() => {
    'tipo_ausencia_id': tipo.id,
    'fecha_inicio': fechaApi(fechaInicio),
    'fecha_fin': fechaApi(fechaFin),
    'dias_solicitados': diasSolicitados.toString(),
    'motivo': motivo.trim(),
  };

  /// Días hábiles (lunes a viernes) entre dos fechas, ambas incluidas.
  ///
  /// >>> VERIFICA con el backend <<<  Las vacaciones en Bolivia se cuentan
  /// en días hábiles. No se descuentan feriados: el móvil no tiene ese
  /// calendario. El backend es la autoridad y puede recalcular.
  static int diasHabiles(DateTime inicio, DateTime fin) {
    final desde = DateTime(inicio.year, inicio.month, inicio.day);
    final hasta = DateTime(fin.year, fin.month, fin.day);
    if (hasta.isBefore(desde)) return 0;

    var dias = 0;
    // Se avanza con DateTime(año, mes, día + 1) y no sumando 24 horas,
    // para no saltarse días si cambia la hora oficial.
    for (
      var d = desde;
      !d.isAfter(hasta);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      if (d.weekday <= DateTime.friday) dias++;
    }
    return dias;
  }

  /// Por qué NO se puede enviar con estos días, o null si se puede.
  ///
  /// Es la regla de "el saldo nunca queda negativo" (caso 4 de T3-23),
  /// adelantada al teléfono: el colaborador lo sabe antes de enviar. El
  /// backend vuelve a validarlo igual.
  static String? problemaConLosDias({
    required TipoAusencia tipo,
    required int dias,
    required SaldoVacacion? saldo,
  }) {
    if (dias == 0) {
      return 'Las fechas elegidas no tienen días hábiles (de lunes a viernes).';
    }

    if (tipo.descuentaVacacion) {
      final disponibles = saldo?.diasSaldo;
      if (disponibles == null) {
        return 'No tienes saldo de vacaciones asignado. Consulta con '
            'Recursos Humanos.';
      }
      if (dias > disponibles) {
        return 'Saldo insuficiente: pides ${_dias(dias)} y tienes '
            '${SaldoVacacion.dias(disponibles)} disponibles.';
      }
    }

    final maximo = tipo.diasMaximosAnio;
    if (maximo != null && dias > maximo) {
      return '${tipo.nombre} permite hasta $maximo días al año.';
    }
    return null;
  }

  /// "2026-11-02": el formato date de FastAPI.
  static String fechaApi(DateTime f) =>
      '${f.year}-${_dos(f.month)}-${_dos(f.day)}';

  /// "02/11/2026": lo que se muestra en el formulario.
  static String fechaCorta(DateTime f) =>
      '${_dos(f.day)}/${_dos(f.month)}/${f.year}';

  static String _dias(int n) => n == 1 ? '1 día hábil' : '$n días hábiles';

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
