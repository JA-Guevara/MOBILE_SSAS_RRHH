import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/equipo/model/contrato.dart';
import 'package:mobile_ssas_rrhh/shared/referencias/referencias.dart';

/// Una persona que le reporta al jefe autenticado, con su cargo y su
/// asistencia de hoy (T3-29 · HU-12 · CU-20).
///
/// NO se lee de un JSON: la arma EquipoService uniendo tablas por llaves.
///   contrato   -> la fila (VIGENTE, jefe_directo_id = el jefe)
///   empleado   -> por contrato.empleado_id   (GET /empleados, ya existe)
///   cargo      -> por contrato.cargo_id      (GET /cargos, ya existe)
///   asistencia -> por asistencia.empleado_id = contrato.empleado_id
class MiembroEquipo {
  final Contrato contrato;

  /// Null si el empleado no vino en GET /empleados.
  final EmpleadoRef? empleado;

  /// Null si el cargo no vino en GET /cargos.
  final CargoRef? cargo;

  /// La fila de asistencia de hoy. Null si todavía no marcó nada.
  final Asistencia? asistencia;

  const MiembroEquipo({
    required this.contrato,
    this.empleado,
    this.cargo,
    this.asistencia,
  });

  // ------------------------------------------------------------- para mostrar

  /// "Lucía Fernández Rojas". Si el nombre no se pudo resolver, se muestra
  /// el número de contrato para que el jefe tenga al menos una referencia.
  String get nombreCompleto =>
      empleado?.nombreCompleto ??
      'Contrato ${contrato.numeroContrato ?? contrato.id}';

  /// "LF" para el avatar; "?" si no hay nombre.
  String get iniciales {
    final i = empleado?.iniciales ?? '';
    return i.isEmpty ? '?' : i;
  }

  /// Nombre del cargo del contrato vigente.
  String? get cargoNombre => cargo?.nombre;

  /// Cómo está hoy. Ver [EstadoDia].
  EstadoDia get estadoDia {
    final a = asistencia;
    // Una falta, vacación o permiso la registra el backend sin horas: si
    // el estado lo dice, manda sobre las horas.
    if (a != null && _esAusencia(a.estado)) return EstadoDia.ausente;
    if (a == null || !a.tieneEntrada) return EstadoDia.sinMarcar;
    if (!a.tieneSalida) return EstadoDia.enJornada;
    return EstadoDia.salio;
  }

  /// >>> VERIFICA contra /docs <<<  Los literales de asistencia.estado no
  /// están definidos en ningún plan. Se reconocen por prefijo, como en la
  /// bandeja de T3-22, para aguantar "FALTA", "falta_injustificada"...
  static bool _esAusencia(String? estado) {
    final e = (estado ?? '').trim().toLowerCase();
    return e.startsWith('falt') ||
        e.startsWith('ausen') ||
        e.startsWith('vacac') ||
        e.startsWith('permis') ||
        e.startsWith('licenc') ||
        e.startsWith('baja');
  }

  /// La línea de detalle de la tarjeta:
  ///   en jornada -> "Entró 08:03 · 3 min tarde"
  ///   salió      -> "08:03 a 17:12"
  ///   ausente    -> "Vacación" (el estado que mandó el backend)
  ///   sin marcar -> "Todavía no marcó su entrada"
  String get detalleDia {
    final a = asistencia;
    switch (estadoDia) {
      case EstadoDia.sinMarcar:
        return 'Todavía no marcó su entrada';
      case EstadoDia.ausente:
        return _capitalizar(a?.estado ?? '');
      case EstadoDia.salio:
        return a!.resumenHoras;
      case EstadoDia.enJornada:
        final retraso = a!.minutosRetraso ?? 0;
        return [
          'Entró ${a.entradaCorta}',
          if (retraso > 0) '$retraso min tarde',
        ].join(' · ');
    }
  }

  /// "VACACION" -> "Vacación"; "falta_injustificada" -> "Falta
  /// injustificada". Si no lo reconoce, lo muestra tal cual con mayúscula.
  static String _capitalizar(String estado) {
    final limpio = estado.trim().replaceAll('_', ' ').toLowerCase();
    if (limpio.isEmpty) return 'Ausente';
    if (limpio == 'vacacion') return 'Vacación';
    return limpio[0].toUpperCase() + limpio.substring(1);
  }
}

/// Cómo está una persona del equipo hoy. El orden es el del resumen.
enum EstadoDia { enJornada, salio, sinMarcar, ausente }
