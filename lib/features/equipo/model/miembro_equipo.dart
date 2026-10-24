import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// Una persona que le reporta al jefe autenticado, con su cargo y su
/// asistencia de hoy (T3-29 · HU-12 · CU-20).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API para la
/// fila del equipo. Cruza tres tablas:
///   empleado   -> id, codigo, nombres, apellido_paterno, apellido_materno
///   contrato   -> cargo_id (resuelto a [cargo]) y jefe_directo_id, que es
///                 el filtro: el backend devuelve solo los contratos
///                 VIGENTES cuyo jefe_directo_id es el empleado del token
///   asistencia -> fecha, hora_entrada, hora_salida, estado (a través de
///                 [asistencia], que reutiliza el modelo de T3-18)
class MiembroEquipo {
  /// Id del empleado, no del contrato: es lo que identifica a la persona.
  final String id;

  final String? codigo;
  final String nombres;
  final String apellidoPaterno;
  final String? apellidoMaterno;

  /// Nombre del cargo vigente, ya resuelto desde contrato.cargo_id.
  final String? cargo;

  /// La marca de hoy. Null si todavía no marcó nada.
  final Asistencia? asistencia;

  const MiembroEquipo({
    required this.id,
    required this.nombres,
    required this.apellidoPaterno,
    this.codigo,
    this.apellidoMaterno,
    this.cargo,
    this.asistencia,
  });

  /// >>> VERIFICA estas claves contra /docs y ajústalas si difieren. <<<
  /// El endpoint todavía no existe (T3-01 y T3-05 sin construir).
  factory MiembroEquipo.fromJson(Map<String, dynamic> json) {
    // Los datos del empleado pueden venir planos o anidados en
    // "empleado": {...}, igual que el postulante en el ranking de T2-20.
    final sub = json['empleado'];
    final empleado = sub is Map<String, dynamic> ? sub : json;

    final asistenciaJson = json['asistencia'];

    return MiembroEquipo(
      id: leerId(empleado['id'] ?? json['empleado_id']) ?? '',
      codigo: empleado['codigo'] as String?,
      nombres: (empleado['nombres'] ?? '') as String,
      apellidoPaterno: (empleado['apellido_paterno'] ?? '') as String,
      apellidoMaterno: empleado['apellido_materno'] as String?,
      cargo: _cargo(json['cargo']),
      asistencia: asistenciaJson is Map<String, dynamic>
          ? Asistencia.fromJson(asistenciaJson)
          : null,
    );
  }

  /// El cargo puede llegar resuelto como {"id", "nombre"} o como texto.
  static String? _cargo(Object? valor) {
    if (valor is Map<String, dynamic>) return valor['nombre'] as String?;
    if (valor is String && valor.trim().isNotEmpty) return valor.trim();
    return null;
  }

  // ------------------------------------------------------------- para mostrar

  /// "Lucía Fernández Rojas". No deja espacios sueltos si falta algo.
  String get nombreCompleto => [
    nombres,
    apellidoPaterno,
    apellidoMaterno ?? '',
  ].where((s) => s.isNotEmpty).join(' ');

  /// "LF" para el avatar.
  String get iniciales {
    final a = nombres.isNotEmpty ? nombres[0] : '';
    final b = apellidoPaterno.isNotEmpty ? apellidoPaterno[0] : '';
    return (a + b).toUpperCase();
  }

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
