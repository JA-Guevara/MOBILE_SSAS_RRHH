import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/staff_portal_page.dart';

void main() {
  testWidgets('muestra el acceso real del personal', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StaffPortalPage(restoreSession: false),
    ));
    expect(find.text('Acceso de personal'), findsOneWidget);
    expect(find.text('Correo o usuario'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
