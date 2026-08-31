import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/main.dart';

/// Comprueba que el arranque de la app de capturas funciona con CADA valor
/// del enum Pantalla.
///
/// Esta prueba existe por una razón concreta: en lib/main.dart las pantallas
/// se resuelven con un Map y no con un `switch` exhaustivo, así que el
/// compilador ya no avisa si añades una pantalla al enum y olvidas darla de
/// alta. Este archivo hace ese trabajo.
void main() {
  test('cada valor de Pantalla tiene su bloque MODO en el mapa', () {
    for (final pantalla in Pantalla.values) {
      expect(
        pantallas[pantalla],
        isNotNull,
        reason:
            'Falta "Pantalla.${pantalla.name}" en el mapa "pantallas" de '
            'lib/main.dart. Añade su línea y su función.',
      );
    }
  });

  // Una prueba por pantalla: si una se cae, el nombre dice cuál.
  for (final pantalla in Pantalla.values) {
    testWidgets('la app arranca con Pantalla.${pantalla.name}', (tester) async {
      // Lienzo alto: algunas pantallas no caben en el tamaño por defecto y
      // un desbordamiento cuenta como excepción.
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(AppSSAH(pantalla: pantalla));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
