import 'package:geolocator/geolocator.dart';

/// Resultado de pedir la ubicación. Es un sealed class para que la pantalla
/// tenga que contemplar todos los casos: si mañana se añade uno nuevo, el
/// switch deja de compilar en vez de fallar en silencio.
sealed class ResultadoUbicacion {
  const ResultadoUbicacion();
}

/// El colaborador concedió el permiso y se pudo leer el GPS.
class UbicacionObtenida extends ResultadoUbicacion {
  final double latitud;
  final double longitud;

  const UbicacionObtenida({required this.latitud, required this.longitud});
}

/// Denegó el permiso. Si [permanente] es true, Android/iOS ya no vuelven a
/// preguntar: el único camino es que lo active a mano en los ajustes.
class UbicacionDenegada extends ResultadoUbicacion {
  final bool permanente;

  const UbicacionDenegada({required this.permanente});
}

/// El permiso está, pero el GPS del teléfono está apagado.
class UbicacionSinServicio extends ResultadoUbicacion {
  const UbicacionSinServicio();
}

/// Cualquier otro fallo al leer el GPS (sin señal, tiempo agotado...).
class UbicacionFallida extends ResultadoUbicacion {
  final String mensaje;

  const UbicacionFallida(this.mensaje);
}

/// Pide el permiso de ubicación y lee la posición actual.
///
/// Se separa del resto para que la pantalla no dependa de geolocator: así
/// hay fakes para las capturas y para los tests, que no pueden tocar el GPS.
class UbicacionService {
  const UbicacionService();

  /// Pide permiso si hace falta y devuelve la posición. Nunca lanza: todos
  /// los caminos se devuelven como un [ResultadoUbicacion].
  Future<ResultadoUbicacion> actual() async {
    // 1. El GPS del teléfono tiene que estar encendido. Sin esto, pedir el
    //    permiso no sirve de nada.
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const UbicacionSinServicio();
    }

    // 2. Los tres casos del permiso.
    var permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      // Denegado pero todavía se puede preguntar.
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever) {
      return const UbicacionDenegada(permanente: true);
    }
    if (permiso == LocationPermission.denied) {
      // Dijo que no en el diálogo que acabamos de mostrar.
      return const UbicacionDenegada(permanente: false);
    }

    // 3. Concedido (whileInUse o always): se lee la posición.
    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Si en 15 s no hay señal, mejor avisar que dejar la app colgada.
          timeLimit: Duration(seconds: 15),
        ),
      );
      return UbicacionObtenida(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );
    } on Object catch (e) {
      return UbicacionFallida(
        'No se pudo leer tu ubicación. Sal a un lugar despejado e '
        'inténtalo de nuevo.\n($e)',
      );
    }
  }

  /// Abre los ajustes de la app para que el colaborador active el permiso
  /// que denegó permanentemente.
  Future<void> abrirAjustes() => Geolocator.openAppSettings();

  /// Abre los ajustes de ubicación del sistema, para encender el GPS.
  Future<void> abrirAjustesUbicacion() => Geolocator.openLocationSettings();
}
