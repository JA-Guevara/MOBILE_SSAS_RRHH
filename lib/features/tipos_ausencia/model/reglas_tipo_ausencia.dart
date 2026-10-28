import 'package:mobile_ssas_rrhh/features/aprobaciones/model/tipo_ausencia.dart';

/// Lo que se revisa ANTES de guardar un tipo de ausencia (T3-30).
///
/// Los límites salen de la tabla "tipo_ausencia" de rrhh-api: nombre
/// varchar(120), codigo varchar(40) y único por empresa. El backend vuelve
/// a revisarlo; aquí se avisa antes para no gastar un viaje al servidor.
abstract final class ReglasTipoAusencia {
  static const maxNombre = 120;
  static const maxCodigo = 40;

  /// Un tope anual mayor que el año no tiene sentido.
  static const maxDias = 365;

  static String? nombre(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Escribe el nombre del tipo de ausencia.';
    if (v.length > maxNombre) {
      return 'El nombre no puede pasar de $maxNombre caracteres.';
    }
    return null;
  }

  /// [otros] son los códigos de los DEMÁS tipos de la empresa: el código
  /// tiene que ser único.
  static String? codigo(String? valor, Iterable<String> otros) {
    final v = normalizarCodigo(valor ?? '');
    if (v.isEmpty) return 'Escribe el código, por ejemplo VAC.';
    if (v.contains(' ')) return 'El código no lleva espacios.';
    if (v.length > maxCodigo) {
      return 'El código no puede pasar de $maxCodigo caracteres.';
    }
    if (otros.map(normalizarCodigo).contains(v)) {
      return 'Ya hay otro tipo de ausencia con el código $v.';
    }
    return null;
  }

  /// Vacío es válido: significa "sin tope anual".
  static String? tope(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return null;
    final dias = int.tryParse(v);
    if (dias == null || dias < 1 || dias > maxDias) {
      return 'El tope va de 1 a $maxDias días. Déjalo vacío si no tiene '
          'tope.';
    }
    return null;
  }

  /// "vac " -> "VAC": así se guardan los códigos.
  static String normalizarCodigo(String valor) => valor.trim().toUpperCase();

  /// El texto del campo "tope" como número, o null si está vacío.
  static int? leerTope(String valor) => int.tryParse(valor.trim());

  /// "Hasta 15 días al año", "Hasta 1 día al año" o "Sin tope anual".
  static String textoTope(int? dias) => switch (dias) {
    null => 'Sin tope anual',
    1 => 'Hasta 1 día al año',
    _ => 'Hasta $dias días al año',
  };

  /// Si el formulario cambió algo respecto al tipo original. Se comparan
  /// los cuerpos que se mandarían al backend: si son iguales, no hay nada
  /// que guardar.
  static bool cambio(TipoAusencia original, TipoAusencia editado) {
    final a = original.toJson();
    final b = editado.toJson();
    return a.keys.any((k) => a[k] != b[k]);
  }

  /// Activos primero y, dentro de cada grupo, por nombre.
  static int orden(TipoAusencia a, TipoAusencia b) {
    if (a.activo != b.activo) return a.activo ? -1 : 1;
    return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
  }
}
