import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/app/app.dart';
import 'package:mobile_ssas_rrhh/app/providers/app_providers.dart';

void main() {
  testWidgets('muestra el formulario de inicio de sesión', (tester) async {
    await tester.pumpWidget(const AppProviders(child: App()));
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
