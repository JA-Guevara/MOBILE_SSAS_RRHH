import 'package:mobile_ssas_rrhh/features/asistencia/data/ubicacion_service.dart';

/// Ubicaciones FALSAS para capturar pantallas y correr tests sin GPS.
///
/// Un test no puede pedir permisos ni leer el GPS, y en el escritorio no hay
/// sensor: por eso la pantalla recibe el servicio de ubicación inyectado.

/// Concede el permiso y devuelve unas coordenadas de Santa Cruz.
class UbicacionServiceFalso extends UbicacionService {
  const UbicacionServiceFalso();

  @override
  Future<ResultadoUbicacion> actual() async {
    // Simula la demora de fijar el GPS, para ver el botón bloqueado.
    await Future.delayed(const Duration(milliseconds: 900));
    return const UbicacionObtenida(latitud: -17.783327, longitud: -63.182140);
  }
}

/// El colaborador dijo que no, pero se le puede volver a preguntar.
class UbicacionServiceDenegada extends UbicacionService {
  const UbicacionServiceDenegada();

  @override
  Future<ResultadoUbicacion> actual() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const UbicacionDenegada(permanente: false);
  }
}

/// Denegado para siempre: solo se arregla desde los ajustes del teléfono.
class UbicacionServiceDenegadaPermanente extends UbicacionService {
  const UbicacionServiceDenegadaPermanente();

  @override
  Future<ResultadoUbicacion> actual() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const UbicacionDenegada(permanente: true);
  }

  @override
  Future<void> abrirAjustes() async {
    // En los fakes no se abre nada: no hay ajustes que abrir.
  }
}

/// El permiso está concedido pero el GPS del teléfono está apagado.
class UbicacionServiceSinGps extends UbicacionService {
  const UbicacionServiceSinGps();

  @override
  Future<ResultadoUbicacion> actual() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const UbicacionSinServicio();
  }

  @override
  Future<void> abrirAjustesUbicacion() async {}
}
