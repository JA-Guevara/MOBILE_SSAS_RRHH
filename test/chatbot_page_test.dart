import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/app/chatbot_page.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/postulantes_page.dart';

class _ChatApi extends StaffApi {
  _ChatApi() : super(baseUrl: 'https://example.test/api/v1');

  @override
  Future<List<String>> chatbotSuggestions() async => ['¿Cómo hago reportes?'];

  @override
  Future<Map<String, dynamic>> askChatbot(String question) async => {
    'respuesta': 'Abre Reportes para consultar los resultados.',
    'fuentes': <Object>[],
    'enlaces': [
      {'titulo': 'Ver reportes', 'ruta': '/reportes'},
      {'titulo': 'Usuarios web', 'ruta': '/usuarios'},
      {'titulo': 'Enlace externo', 'ruta': 'https://example.test/otro'},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> applicants({
    int offset = 0,
    int limit = 50,
  }) async => [
    {'nombres': 'Ana', 'apellidos': 'Paz', 'ciudad': 'La Paz'},
  ];
}

void main() {
  testWidgets('muestra enlaces locales del chatbot y devuelve la ruta', (
    tester,
  ) async {
    final api = _ChatApi();
    addTearDown(api.close);
    String? selectedRoute;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selectedRoute = await Navigator.of(context).push<String>(
                  MaterialPageRoute<String>(
                    builder: (_) => ChatbotPage.personal(staffApi: api),
                  ),
                );
              },
              child: const Text('Abrir chat'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¿Cómo hago reportes?'));
    await tester.pumpAndSettle();

    expect(
      find.text('Abre Reportes para consultar los resultados.'),
      findsOneWidget,
    );
    expect(find.text('Ver reportes'), findsOneWidget);
    expect(find.text('Usuarios web'), findsOneWidget);
    expect(find.text('Enlace externo'), findsNothing);

    await tester.tap(find.text('Usuarios web'));
    await tester.pumpAndSettle();
    expect(
      find.text('Esta sección está disponible en la web.'),
      findsOneWidget,
    );
    expect(selectedRoute, isNull);

    await tester.tap(find.text('Ver reportes'));
    await tester.pumpAndSettle();
    expect(selectedRoute, '/reportes');
  });

  testWidgets('muestra postulantes con datos mínimos', (tester) async {
    final api = _ChatApi();
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(home: PostulantesPage(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Ana Paz'), findsOneWidget);
    expect(find.text('La Paz'), findsOneWidget);
    expect(find.text('Página 1'), findsOneWidget);
  });
}
