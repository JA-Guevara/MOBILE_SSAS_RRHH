import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_ssas_rrhh/features/ranking/data/ranking_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/ranking/ui/ranking_page.dart';
import 'package:mobile_ssas_rrhh/features/ranking/ui/widgets/candidato_card.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/model/etapa_postulacion.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

Widget _app(Widget hijo) => MaterialApp(theme: AppTheme.light, home: hijo);

void main() {
  testWidgets('con datos: ordena de mayor a menor afinidad', (tester) async {
    // ListView.builder solo construye lo que cabe en pantalla. El lienzo por
    // defecto (800x600) deja fuera las dos últimas tarjetas, así que se
    // agranda para poder comprobar la lista entera.
    tester.view.physicalSize = const Size(500, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        RankingPage(
          vacanteId: 1,
          vacanteTitulo: 'Desarrollador Backend',
          service: RankingServiceFalso(),
        ),
      ),
    );

    // Estado 1: cargando
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Desarrollador Backend'), findsOneWidget);
    expect(
      find.text('6 postulantes · ordenados por afinidad de IA'),
      findsOneWidget,
    );

    // El fake devuelve los candidatos desordenados a propósito.
    final tarjetas = tester
        .widgetList<CandidatoCard>(find.byType(CandidatoCard))
        .toList();
    final afinidades = tarjetas.map((t) => t.candidato.puntajeIa).toList();

    expect(afinidades, [87, 81, 78, 74, 41, null]);
    expect(tarjetas.first.candidato.nombreCompleto, 'Julia Quispe');

    // Pablo Arias no tiene puntaje_ia: va último y sin insignia lila.
    expect(tarjetas.last.candidato.nombreCompleto, 'Pablo Arias');
    expect(find.byType(ChipAfinidad), findsNWidgets(5));
  });

  test('el chip usa etapa_reclutamiento.color, y los tokens como respaldo', () {
    // Formatos que debe aceptar.
    expect(parseColorEtapa('#7A5AA6'), const Color(0xFF7A5AA6));
    expect(parseColorEtapa('7A5AA6'), const Color(0xFF7A5AA6));
    expect(parseColorEtapa('  #7a5aa6  '), const Color(0xFF7A5AA6));
    expect(parseColorEtapa('#807A5AA6'), const Color(0x807A5AA6));

    // Valores que obligan a caer al respaldo de tokens.
    expect(parseColorEtapa(null), isNull);
    expect(parseColorEtapa(''), isNull);
    expect(parseColorEtapa('rojo'), isNull);
    expect(parseColorEtapa('#ZZZZZZ'), isNull);
  });

  testWidgets('etapa con color: el chip lo respeta', (tester) async {
    const etapa = EtapaPostulacion(
      id: 2,
      nombre: 'Preselección',
      orden: 2,
      color: '#7A5AA6',
    );
    await tester.pumpWidget(
      _app(const Scaffold(body: ChipEtapa(etapa: etapa))),
    );

    final texto = tester.widget<Text>(find.text('Preselección'));
    expect(texto.style?.color, const Color(0xFF7A5AA6));
  });

  testWidgets('etapa sin color: el chip cae a los tokens', (tester) async {
    const etapa = EtapaPostulacion(
      id: 4,
      nombre: 'Oferta',
      orden: 4,
      esContratado: true,
    );
    await tester.pumpWidget(
      _app(const Scaffold(body: ChipEtapa(etapa: etapa))),
    );

    final texto = tester.widget<Text>(find.text('Oferta'));
    expect(texto.style?.color, AppColors.verde600);
  });

  testWidgets('sin postulantes: estado vacío', (tester) async {
    await tester.pumpWidget(
      _app(
        RankingPage(
          vacanteId: 1,
          vacanteTitulo: 'Desarrollador Backend',
          service: RankingServiceVacio(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('todavía no tiene postulantes'), findsOneWidget);
  });

  testWidgets('error de red: mensaje y Reintentar', (tester) async {
    await tester.pumpWidget(
      _app(
        RankingPage(
          vacanteId: 1,
          vacanteTitulo: 'Desarrollador Backend',
          service: RankingServiceError(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo cargar el ranking'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('401: distingue sesión expirada de fallo de red', (tester) async {
    await tester.pumpWidget(
      _app(
        RankingPage(
          vacanteId: 1,
          vacanteTitulo: 'Desarrollador Backend',
          service: RankingServiceSinSesion(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tu sesión expiró'), findsOneWidget);
  });
}
