import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// Un backend de mentira que habla HTTP, para los servicios FALSOS.
///
/// POR QUÉ EXISTE: los fakes del Sprint 3 no reemplazan los métodos del
/// servicio; le pasan al servicio REAL un cliente que, en vez de salir a
/// internet, contesta con filas de las tablas del diagrama. Así, en las
/// capturas y en las pruebas corre el mismo código que correrá contra
/// rrhh-api: las rutas, la lectura de columnas y la unión de tablas por sus
/// llaves. Cuando el backend publique los endpoints, lo único que cambia es
/// este cliente por el de verdad.
///
/// [responder] recibe la petición y devuelve el cuerpo JSON (un Map, una
/// List o null). Para simular un error, lanza [ErrorFalso].
AppHttpClient clienteFalso(
  FutureOr<Object?> Function(PeticionFalsa peticion) responder, {
  Duration demora = const Duration(milliseconds: 700),
}) {
  final mock = MockClient((req) async {
    // Simula la demora de la red, para ver el estado "cargando".
    await Future<void>.delayed(demora);

    // Un formulario con adjunto llega como multipart: su cuerpo no es JSON y
    // req.body ni siquiera se puede leer como texto si trae un PDF.
    final tipo = req.headers['content-type'] ?? '';
    final multipart = tipo.startsWith('multipart/form-data')
        ? _leerMultipart(req.bodyBytes, tipo)
        : null;
    final cuerpo = multipart != null || req.body.isEmpty
        ? null
        : jsonDecode(req.body);

    final peticion = PeticionFalsa(
      metodo: req.method,
      ruta: req.url.path.replaceFirst(_prefijo, ''),
      query: req.url.queryParameters,
      cuerpo: cuerpo is Map<String, dynamic> ? cuerpo : null,
      campos: multipart?.campos ?? const {},
      archivos: multipart?.archivos ?? const {},
    );

    try {
      final respuesta = await responder(peticion);
      return _json(respuesta, 200);
    } on ErrorFalso catch (e) {
      return _json({'detail': e.detalle}, e.status);
    }
  });

  return AppHttpClient(baseUrl: 'https://falso$_prefijo', client: mock);
}

/// Un TokenStorage con un token cualquiera: el backend falso no lo revisa,
/// pero así el servicio manda el header igual que en producción.
TokenStorage sesionFalsa() =>
    MemoryTokenStorage()..saveAccessToken('token-falso');

/// La petición que recibe el backend falso, ya sin el prefijo /api/v1.
class PeticionFalsa {
  final String metodo;
  final String ruta;
  final Map<String, String> query;
  final Map<String, dynamic>? cuerpo;

  /// Los campos de texto de un formulario multipart.
  final Map<String, String> campos;

  /// Los archivos de un formulario multipart, por el nombre de su parte.
  final Map<String, ArchivoFalso> archivos;

  const PeticionFalsa({
    required this.metodo,
    required this.ruta,
    required this.query,
    this.cuerpo,
    this.campos = const {},
    this.archivos = const {},
  });

  bool es(String metodo, String ruta) =>
      this.metodo == metodo && this.ruta == ruta;

  @override
  String toString() => '$metodo $ruta';
}

/// Lo que lanza el backend falso para responder con un error HTTP. El
/// cuerpo sale como {"detail": ...}, igual que en FastAPI.
class ErrorFalso implements Exception {
  final int status;
  final String detalle;

  const ErrorFalso(this.status, this.detalle);

  /// Ruta que el backend falso no conoce: si aparece, el servicio está
  /// llamando a algo que el fake no simula.
  factory ErrorFalso.rutaDesconocida(PeticionFalsa p) =>
      ErrorFalso(404, 'El backend falso no conoce $p');
}

/// Un archivo recibido en un multipart: lo que el backend falso necesita
/// para decidir (que llegó, cómo se llama y cuánto pesa).
class ArchivoFalso {
  final String nombre;
  final int bytes;

  const ArchivoFalso({required this.nombre, required this.bytes});
}

/// Separa un cuerpo multipart/form-data en campos de texto y archivos.
///
/// Se lee como latin1 porque latin1 convierte cada byte en un carácter sin
/// perder nada: así se puede partir por el boundary aunque haya un PDF en
/// medio. Los valores de texto se vuelven a pasar a UTF-8 para las tildes.
({Map<String, String> campos, Map<String, ArchivoFalso> archivos})
_leerMultipart(List<int> bytes, String contentType) {
  final campos = <String, String>{};
  final archivos = <String, ArchivoFalso>{};

  final boundary = RegExp(r'boundary="?([^";]+)"?')
      .firstMatch(contentType)
      ?.group(1);
  if (boundary == null) return (campos: campos, archivos: archivos);

  for (final parte in latin1.decode(bytes).split('--$boundary')) {
    final corte = parte.indexOf('\r\n\r\n');
    if (corte == -1) continue;

    final cabeceras = parte.substring(0, corte);
    var contenido = parte.substring(corte + 4);
    if (contenido.endsWith('\r\n')) {
      contenido = contenido.substring(0, contenido.length - 2);
    }

    final nombre = RegExp(r'[;\s]name="([^"]*)"')
        .firstMatch(cabeceras)
        ?.group(1);
    if (nombre == null) continue;

    final crudo = latin1.encode(contenido);
    final archivo = RegExp(r'filename="([^"]*)"').firstMatch(cabeceras);
    if (archivo != null) {
      archivos[nombre] = ArchivoFalso(
        nombre: archivo.group(1)!,
        bytes: crudo.length,
      );
    } else {
      campos[nombre] = utf8.decode(crudo, allowMalformed: true);
    }
  }
  return (campos: campos, archivos: archivos);
}

const _prefijo = '/api/v1';

http.Response _json(Object? cuerpo, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(cuerpo)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
