import 'package:mobile_ssas_rrhh/shared/format/json_id.dart';

/// Las tablas del Sprint 3 guardan llaves (empleado_id, cargo_id), no
/// nombres. Para mostrarle a una persona algo legible, la app resuelve esas
/// llaves contra los endpoints que YA EXISTEN en rrhh-api:
///
///   GET /empleados   -> EmpleadoResponse  (seleccion_schemas.py)
///   GET /cargos      -> CargoResponse     (cargos/http/schemas.py)
///
/// Aquí se leen SOLO las claves que esos endpoints devuelven hoy. No son
/// tablas nuevas: se usan únicamente para traducir una llave a un nombre.

/// Una fila de GET /empleados, reducida a lo que se muestra.
class EmpleadoRef {
  final String id;
  final String? codigo;
  final String nombres;
  final String apellidoPaterno;
  final String? apellidoMaterno;

  const EmpleadoRef({
    required this.id,
    required this.nombres,
    required this.apellidoPaterno,
    this.codigo,
    this.apellidoMaterno,
  });

  factory EmpleadoRef.fromJson(Map<String, dynamic> json) => EmpleadoRef(
    id: leerId(json['id']) ?? '',
    codigo: json['codigo'] as String?,
    nombres: (json['nombres'] ?? '') as String,
    apellidoPaterno: (json['apellido_paterno'] ?? '') as String,
    apellidoMaterno: json['apellido_materno'] as String?,
  );

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
}

/// Una fila de GET /cargos, reducida a lo que se muestra.
class CargoRef {
  final String id;
  final String nombre;

  const CargoRef({required this.id, required this.nombre});

  factory CargoRef.fromJson(Map<String, dynamic> json) => CargoRef(
    id: leerId(json['id']) ?? '',
    nombre: (json['nombre'] ?? '') as String,
  );
}

/// Convierte una lista de filas en un mapa por id, para unir tablas.
Map<String, T> porId<T>(
  Iterable<Map<String, dynamic>> filas,
  T Function(Map<String, dynamic>) leer,
  String Function(T) id,
) => {for (final valor in filas.map(leer)) id(valor): valor};
