import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/ubicacion_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/model/asistencia.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/ui/asistencia_page.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

void main() {
  test('el modelo saca HH:MM de los formatos que puede mandar el backend', () {
    const columnaTime = Asistencia(id: '1', horaEntrada: '08:03:00');
    expect(columnaTime.entradaCorta, '08:03');

    const isoCompleto = Asistencia(id: '1', horaEntrada: '2026-08-29T08:03:00');
    expect(isoCompleto.entradaCorta, '08:03');

    const yaCorto = Asistencia(id: '1', horaEntrada: '08:03');
    expect(yaCorto.entradaCorta, '08:03');

    // Sin marcar y cadena vacía significan lo mismo.
    const vacio = Asistencia(id: '1');
    expect(vacio.entradaCorta, '—:—');
    expect(vacio.resumenHoras, '—:— a —:—');
  });

  test('qué toca marcar según lo que ya está registrado', () {
    const sinNada = Asistencia(id: '1');
    expect(sinNada.pendiente, MarcaPendiente.entrada);

    const conEntrada = Asistencia(id: '1', horaEntrada: '08:03:00');
    expect(conEntrada.pendiente, MarcaPendiente.salida);

    const completo = Asistencia(
      id: '1',
      horaEntrada: '08:03:00',
      horaSalida: '17:12:00',
    );
    expect(completo.pendiente, MarcaPendiente.ninguna);
    expect(completo.diaCompleto, isTrue);
  });

  testWidgets('sin marcar: el botón ofrece marcar entrada', (tester) async {
    await tester.pumpWidget(
      _app(
        AsistenciaPage(
          service: AsistenciaServiceSinMarcar(),
          ubicacion: const UbicacionServiceFalso(),
        ),
      ),
    );

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Colaborador'), findsOneWidget);
    expect(find.text('Asistencia'), findsOneWidget);
    expect(find.text('Marcar\nentrada'), findsOneWidget);
    // La línea del día se dibuja con Text.rich (las horas van en negrita),
    // así que hay que pedirle al buscador que mire dentro de los TextSpan.
    expect(find.text('Hoy · —:— a —:—', findRichText: true), findsOneWidget);
    expect(
      find.text('Captura lat/long al marcar · una marca por día'),
      findsOneWidget,
    );
  });

  testWidgets('marcar entrada avanza el botón a salida', (tester) async {
    await tester.pumpWidget(
      _app(
        AsistenciaPage(
          service: AsistenciaServiceSinMarcar(),
          ubicacion: const UbicacionServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar\nentrada'));
    await tester.pumpAndSettle();

    expect(find.text('Marcar\nsalida'), findsOneWidget);
    expect(find.text('Hoy · 08:03 a —:—', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Entrada registrada a las 08:03'),
      findsOneWidget,
    );
  });

  testWidgets('día completo: el botón queda deshabilitado', (tester) async {
    await tester.pumpWidget(
      _app(
        AsistenciaPage(
          service: AsistenciaServiceDiaCompleto(),
          ubicacion: const UbicacionServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jornada\ncerrada'), findsOneWidget);
    expect(
      find.text('Hoy · 08:03 a 17:12', findRichText: true),
      findsOneWidget,
    );
    // El backend ya calculó los totales del día cerrado.
    expect(find.textContaining('9.15 h trabajadas'), findsOneWidget);

    final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(boton.onPressed, isNull);
  });

  testWidgets('permiso denegado: se puede volver a pedir', (tester) async {
    await tester.pumpWidget(
      _app(
        AsistenciaPage(
          service: AsistenciaServiceSinMarcar(),
          ubicacion: const UbicacionServiceDenegada(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar\nentrada'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Necesitamos tu ubicación'), findsOneWidget);
    expect(find.text('Permitir ubicación'), findsOneWidget);
    // No se marcó nada: sigue sin entrada.
    expect(find.text('Marcar\nentrada'), findsOneWidget);
  });

  testWidgets('denegado permanentemente: manda a los ajustes', (tester) async {
    await tester.pumpWidget(
      _app(
        AsistenciaPage(
          service: AsistenciaServiceSinMarcar(),
          ubicacion: const UbicacionServiceDenegadaPermanente(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar\nentrada'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ajustes del teléfono'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsOneWidget);
  });

  testWidgets('GPS apagado: ofrece encenderlo', (tester) async {
    await tester.pumpWidget(
      _app(
        AsistenciaPage(
          service: AsistenciaServiceSinMarcar(),
          ubicacion: const UbicacionServiceSinGps(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar\nentrada'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('GPS de tu teléfono está apagado'),
      findsOneWidget,
    );
    expect(find.text('Encender ubicación'), findsOneWidget);
  });

  testWidgets('error al consultar el día: mensaje y Reintentar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        AsistenciaPage(
          service: AsistenciaServiceError(),
          ubicacion: const UbicacionServiceFalso(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No se pudo cargar tu asistencia'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
