import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';

/// Lo que el colaborador ve al abrir "Solicitar permiso o vacaciones"
/// (CP-S3-13): los tipos de ausencia que puede pedir y su saldo.
///
/// No define claves del API: reutiliza TipoAusencia y SaldoVacacion de la
/// bandeja del jefe (T3-22). Son las mismas tablas, y la regla del equipo es
/// que las claves de una tabla vivan en un solo modelo.
class OpcionesSolicitud {
  /// Solo los tipos activos, en el orden en que los manda el backend.
  final List<TipoAusencia> tipos;

  /// El saldo de la gestión más reciente. null si al colaborador todavía no
  /// le asignaron vacaciones (por ejemplo, si entró hace menos de un año).
  final SaldoVacacion? saldo;

  const OpcionesSolicitud({required this.tipos, this.saldo});
}
