import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/postulante.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/ui/postulacion_page.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// Formulario de postulación (T1-20 · HU-02 · CU-02).
///
/// El formulario NO se puede enviar entero desde una prueba de widgets: el
/// CV se elige con file_picker, que es un canal de plataforma y no existe en
/// el entorno de pruebas. Así que aquí se comprueban las dos mitades por
/// separado:
///   - la pantalla: que dibuja el formulario y que su validación local frena
///     un envío incompleto;
///   - el servicio: los tres desenlaces (éxito, red caída, 422), llamándolo
///     directamente con un CV armado a mano.

Widget _app(PostulacionesService service) => MaterialApp(
  theme: AppTheme.light,
  home: PostulacionPage(
    slug: 'textiles-oriente',
    empresaNombre: 'Textiles del Oriente',
    vacanteId: 1,
    vacanteTitulo: 'Desarrollador Backend',
    service: service,
  ),
);

/// Lienzo alto: el formulario es largo y hay que poder tocar el botón.
void _lienzoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

CvAdjunto _cv() =>
    CvAdjunto(nombre: 'hoja-de-vida.pdf', bytes: Uint8List.fromList([1, 2, 3]));

const _postulante = Postulante(
  nombres: 'Ariany',
  apellidos: 'Claure',
  email: 'ariany@ejemplo.com',
);

void main() {
  test('el CV conoce su extensión, su tipo y su peso', () {
    final pdf = _cv();
    expect(pdf.extension, 'pdf');
    expect(pdf.extensionValida, isTrue);
    expect(pdf.mimeType, 'application/pdf');
    expect(pdf.pesoValido, isTrue);

    // Una extensión que el portal no acepta se detecta antes de subir nada.
    final exe = CvAdjunto(nombre: 'virus.exe', bytes: Uint8List(0));
    expect(exe.extensionValida, isFalse);
    expect(exe.mimeType, 'application/octet-stream');

    // Un archivo sin extensión no debe romper la pantalla.
    final raro = CvAdjunto(nombre: 'sinextension', bytes: Uint8List(0));
    expect(raro.extension, '');
    expect(raro.extensionValida, isFalse);

    // Y el límite de 5 MB se respeta.
    final gordo = CvAdjunto(
      nombre: 'cv.pdf',
      bytes: Uint8List(CvAdjunto.maxBytes + 1),
    );
    expect(gordo.pesoValido, isFalse);

    expect(CvAdjunto.formatearTamanio(840 * 1024), '840 KB');
    expect(CvAdjunto.formatearTamanio(2 * 1024 * 1024), '2.0 MB');
  });

  test('los campos del multipart usan las claves de la tabla postulante', () {
    const completo = Postulante(
      nombres: 'Ariany',
      apellidos: 'Claure',
      email: 'ariany@ejemplo.com',
      ci: '12345678',
      nivelEducativo: 'Licenciatura',
      aniosExperiencia: 3,
      // Los opcionales vacíos no se mandan: el backend guarda NULL y no
      // una cadena vacía.
      telefono: '',
    );

    final campos = completo.toFields();
    expect(campos['nombres'], 'Ariany');
    expect(campos['nivel_educativo'], 'Licenciatura');
    expect(campos['anios_experiencia'], '3');
    expect(campos.containsKey('telefono'), isFalse);
  });

  test('el servicio falso acepta la postulación y devuelve el código', () async {
    final resultado = await PostulacionesServiceFalso().postular(
      slug: 'textiles-oriente',
      vacanteId: 1,
      postulante: _postulante,
      cv: _cv(),
    );

    expect(resultado.codigoSeguimiento, 'TX-8F4K2');
    expect(resultado.mensaje, isNotNull);
  });

  test('el servicio de error avisa que no se pudo enviar', () async {
    await expectLater(
      PostulacionesServiceError().postular(
        slug: 'textiles-oriente',
        vacanteId: 1,
        postulante: _postulante,
        cv: _cv(),
      ),
      throwsA(
        isA<PostulacionException>()
            .having((e) => e.statusCode, 'statusCode', 503)
            .having(
              (e) => e.message,
              'message',
              contains('No se pudo enviar la postulación'),
            ),
      ),
    );
  });

  test('un 422 señala los campos concretos que rechazó el backend', () async {
    await expectLater(
      PostulacionesServiceValidacion().postular(
        slug: 'textiles-oriente',
        vacanteId: 1,
        postulante: _postulante,
        cv: _cv(),
      ),
      throwsA(
        isA<PostulacionException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having(
              (e) => e.erroresPorCampo.keys.toList()..sort(),
              'campos rechazados',
              ['ci', 'email'],
            ),
      ),
    );
  });

  testWidgets('el formulario se abre vacío y recuerda a qué vacante postulas', (
    tester,
  ) async {
    _lienzoAlto(tester);

    await tester.pumpWidget(_app(PostulacionesServiceFalso()));
    await tester.pumpAndSettle();

    expect(find.text('Tus datos'), findsOneWidget);
    expect(find.text('Postulas a'), findsOneWidget);
    expect(find.text('Desarrollador Backend'), findsOneWidget);

    // Los campos de la tabla "postulante" están en pantalla.
    expect(find.text('Nombres'), findsOneWidget);
    expect(find.text('Apellidos'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Nivel educativo'), findsOneWidget);
    expect(find.text('Enviar postulación'), findsOneWidget);

    // Al entrar no hay nada en rojo: solo se valida tras el primer envío.
    expect(find.textContaining('Ingresa tus nombres'), findsNothing);
  });

  testWidgets('un envío incompleto se frena en el cliente y reclama el CV', (
    tester,
  ) async {
    _lienzoAlto(tester);

    await tester.pumpWidget(_app(PostulacionesServiceFalso()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar postulación'));
    await tester.pumpAndSettle();

    // La validación local evita el viaje inútil al servidor.
    expect(find.textContaining('Ingresa tus nombres'), findsOneWidget);
    expect(find.textContaining('Ingresa tus apellidos'), findsOneWidget);
    expect(find.textContaining('Ingresa tu correo'), findsOneWidget);
    // El CV no vive dentro del Form, así que se reclama aparte.
    expect(find.textContaining('Adjunta tu hoja de vida'), findsOneWidget);

    // Seguimos en el formulario: no se envió nada.
    expect(find.text('Enviar postulación'), findsOneWidget);
  });

  testWidgets('un correo mal escrito se avisa antes de enviar', (tester) async {
    _lienzoAlto(tester);

    await tester.pumpWidget(_app(PostulacionesServiceFalso()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(2), 'ariany.ejemplo');
    await tester.tap(find.text('Enviar postulación'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('El correo no tiene un formato válido'),
      findsOneWidget,
    );
  });
}
