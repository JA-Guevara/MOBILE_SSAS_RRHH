import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/model/entrevista.dart';

/// Servicios FALSOS para desarrollar sin backend, igual que en seguimiento.
///
/// En T2-19 son OBLIGATORIOS por ahora: el backend no tiene nada de
/// entrevistas (T2-02 sin construir). Sirven para las capturas:
///   - por confirmar (virtual)   -> EntrevistaServiceFalso
///   - por confirmar (presencial)-> EntrevistaServicePresencial
///   - ya confirmada             -> EntrevistaServiceConfirmada
///   - sin entrevista            -> EntrevistaServiceVacio
///   - con error al consultar    -> EntrevistaServiceError
///   - con error al confirmar    -> EntrevistaServiceErrorAlConfirmar
///
/// Cuando el backend esté listo, vuelves a usar EntrevistaService normal.
/// No borres este archivo: también sirve para pruebas automatizadas.

/// Entrevista virtual pendiente de confirmar. Al confirmar, cambia a
/// "confirmada" de verdad: si vuelves a consultar, ya sale confirmada.
class EntrevistaServiceFalso extends EntrevistaService {
  EntrevistaServiceFalso() : super(baseUrl: 'falso');

  /// Mismas claves que lee Entrevista.fromJson, para que al cambiar al
  /// backend real no falle nada.
  Map<String, dynamic> datos(String codigo) => {
    'id': 7,
    'codigo_seguimiento': codigo,
    'vacante': 'Desarrollador Backend',
    // Siempre en el futuro, para que el botón Confirmar esté activo.
    'fecha_hora': _enDias(5, hora: 15).toIso8601String(),
    'duracion_minutos': 45,
    'modalidad': 'virtual',
    'lugar': null,
    'enlace': 'https://meet.google.com/abc-defg-hij',
    'entrevistador': 'Ana Rojas · Jefa de RR. HH.',
    'estado': 'programada',
    'confirmada_en': null,
  };

  var _confirmada = false;

  @override
  Future<Entrevista?> porCodigo(String codigo) async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future.delayed(const Duration(milliseconds: 800));
    return _construir(codigo);
  }

  @override
  Future<Entrevista> confirmar(String codigo) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _confirmada = true;
    return _construir(codigo);
  }

  Entrevista _construir(String codigo) {
    final json = datos(codigo);
    if (_confirmada) {
      json['estado'] = 'confirmada';
      json['confirmada_en'] = DateTime.now().toIso8601String();
    }
    return Entrevista.fromJson(json);
  }
}

/// Igual que la anterior, pero presencial: muestra la dirección.
class EntrevistaServicePresencial extends EntrevistaServiceFalso {
  @override
  Map<String, dynamic> datos(String codigo) => {
    ...super.datos(codigo),
    'modalidad': 'presencial',
    'lugar': 'Av. Cristo Redentor #450, 2.º piso · Santa Cruz',
    'enlace': null,
  };
}

/// El postulante ya confirmó: sin botón, con la marca de confirmada.
class EntrevistaServiceConfirmada extends EntrevistaServiceFalso {
  @override
  Map<String, dynamic> datos(String codigo) => {
    ...super.datos(codigo),
    'estado': 'confirmada',
    'confirmada_en': _enDias(-1, hora: 9).toIso8601String(),
  };
}

/// Devuelve null: la postulación todavía no tiene entrevista programada.
class EntrevistaServiceVacio extends EntrevistaService {
  EntrevistaServiceVacio() : super(baseUrl: 'falso');

  @override
  Future<Entrevista?> porCodigo(String codigo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }
}

/// Lanza un error de red al consultar: captura "con error".
class EntrevistaServiceError extends EntrevistaService {
  EntrevistaServiceError() : super(baseUrl: 'falso');

  @override
  Future<Entrevista?> porCodigo(String codigo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw EntrevistaException(
      503,
      'No se pudo consultar tu entrevista. '
      'Revisa tu conexión e inténtalo de nuevo.',
    );
  }
}

/// Consulta bien, pero falla al confirmar: para ver el aviso de error
/// sin perder los datos de la entrevista en pantalla.
class EntrevistaServiceErrorAlConfirmar extends EntrevistaServiceFalso {
  @override
  Future<Entrevista> confirmar(String codigo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw EntrevistaException(
      503,
      'No se pudo confirmar tu asistencia. Inténtalo de nuevo.',
    );
  }
}

/// Fecha a [dias] de hoy, a la [hora] indicada.
DateTime _enDias(int dias, {required int hora}) {
  final hoy = DateTime.now();
  return DateTime(hoy.year, hoy.month, hoy.day + dias, hora);
}
