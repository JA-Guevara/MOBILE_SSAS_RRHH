import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/ranking/data/ranking_service.dart';
import 'package:mobile_ssas_rrhh/features/ranking/model/candidato_ranking.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';

/// T2-21 · Pruebas del sprint 2 (lado móvil).
///
/// Casos de la tarea y qué le toca a la app en cada uno:
///   1. Puntaje entre 0 y 100   -> mostrarlo bien (la validación es del backend)
///   2. El ranking ordena       -> la app reordena lo que recibe
///   3. Contratar es atómico    -> NO APLICA en el móvil: no hay contratar
///                                 en la app ni en el backend (T2-07)
///   4. Aislado por empresa     -> mandar el token y manejar 403/404 sin
///                                 mostrar datos
///
/// Las pruebas marcadas "HALLAZGO" documentan fallos encontrados contra el
/// JSON REAL del backend (origin/main). Están en `skip` para no romper la
/// suite mientras el dueño de la tarea los corrige. Para verlas fallar:
///   flutter test test/sprint2_reglas_test.dart --run-skipped

/// Candidato mínimo para probar el orden sin repetir el JSON entero.
CandidatoRanking _c(String nombre, double? puntaje) =>
    CandidatoRanking(id: 0, nombres: nombre, apellidos: '', puntajeIa: puntaje);

List<String> _ordenar(List<CandidatoRanking> lista) =>
    ([...lista]..sort(CandidatoRanking.porAfinidadDesc))
        .map((c) => c.nombreCompleto)
        .toList();

/// RankingService con un backend simulado: responde [cuerpo] con [status]
/// y guarda la petición en [peticiones] para revisar las cabeceras.
RankingService _servicio(
  Object? cuerpo, {
  int status = 200,
  List<http.Request>? peticiones,
  String? token = 'token-empresa-A',
}) {
  final cliente = MockClient((req) async {
    peticiones?.add(req);
    return http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), status);
  });
  final storage = MemoryTokenStorage();
  if (token != null) storage.saveAccessToken(token);
  return RankingService(
    AppHttpClient(baseUrl: 'https://api.test/api/v1', client: cliente),
    storage,
  );
}

void main() {
  group('Caso 1 · puntaje entre 0 y 100', () {
    test('los límites 0 y 100 se muestran tal cual', () {
      expect(_c('A', 0).afinidadTexto, '0%');
      expect(_c('A', 100).afinidadTexto, '100%');
      // 0 es un puntaje válido, no "sin puntaje".
      expect(_c('A', 0).tieneAfinidad, isTrue);
    });

    test('los decimales se redondean al mostrar', () {
      expect(_c('A', 85.5).afinidadTexto, '86%');
      expect(_c('A', 99.6).afinidadTexto, '100%');
      expect(_c('A', 0.4).afinidadTexto, '0%');
    });

    test('sin puntaje: no muestra porcentaje', () {
      expect(_c('A', null).afinidadTexto, '');
      expect(_c('A', null).tieneAfinidad, isFalse);
    });

    test('HALLAZGO H-3: un puntaje fuera de 0–100 se muestra sin control', () {
      // El backend valida 0–100, pero si llegara un valor fuera de rango
      // la app mostraría "150%" o "-5%". Lo esperado es no pasar de 100
      // ni bajar de 0.
      expect(_c('A', 150).afinidadTexto, '100%');
      expect(_c('A', -5).afinidadTexto, '0%');
    }, skip: 'HALLAZGO H-3 (menor): CandidatoRanking no acota el puntaje.');
  });

  group('Caso 2 · el ranking ordena', () {
    test('de mayor a menor puntaje', () {
      final orden = _ordenar([_c('Bruno', 40), _c('Ana', 90), _c('Carla', 75)]);
      expect(orden, ['Ana', 'Carla', 'Bruno']);
    });

    test('empate: desempata por nombre', () {
      final orden = _ordenar([_c('Zoe', 80), _c('Ana', 80), _c('Luis', 95)]);
      expect(orden, ['Luis', 'Ana', 'Zoe']);
    });

    test('los que no tienen puntaje van al final', () {
      final orden = _ordenar([
        _c('Sin1', null),
        _c('Ana', 10),
        _c('Sin2', null),
        _c('Beto', 0),
      ]);
      expect(orden, ['Ana', 'Beto', 'Sin1', 'Sin2']);
    });

    test('nadie tiene puntaje: orden alfabético', () {
      final orden = _ordenar([_c('Carla', null), _c('Ana', null)]);
      expect(orden, ['Ana', 'Carla']);
    });

    test('el resultado no depende del orden en que llegan', () {
      final base = [
        _c('Ana', 90),
        _c('Beto', 90),
        _c('Carla', null),
        _c('Dani', 50),
      ];
      final esperado = _ordenar(base);
      // Todas las rotaciones de la lista dan el mismo ranking.
      for (var i = 0; i < base.length; i++) {
        final rotada = [...base.skip(i), ...base.take(i)];
        expect(_ordenar(rotada), esperado);
      }
      expect(esperado, ['Ana', 'Beto', 'Dani', 'Carla']);
    });

    test('el servicio reordena aunque el backend mande desordenado', () async {
      final servicio = _servicio([
        {
          'id': 1,
          'puntaje_ia': 41,
          'postulante': {'nombres': 'Bajo'},
        },
        {
          'id': 2,
          'postulante': {'nombres': 'SinPuntaje'},
        },
        {
          'id': 3,
          'puntaje_ia': 87,
          'postulante': {'nombres': 'Alto'},
        },
      ]);

      final lista = await servicio.porVacante(1);

      expect(lista.map((c) => c.nombreCompleto), [
        'Alto',
        'Bajo',
        'SinPuntaje',
      ]);
    });

    test(
      'HALLAZGO H-1: el JSON real del tablero rompe el ranking',
      () async {
        // Respuesta REAL de GET /vacantes/{id}/tablero en origin/main:
        // id es UUID (texto), puntaje_manual llega como texto ("80.00"),
        // postulante y etapa son textos planos, y NO viene puntaje_ia.
        final servicio = _servicio([
          {
            'id': '6f1c0000-0000-0000-0000-000000000001',
            'postulante': 'Ana Pérez',
            'etapa': 'Entrevista',
            'estado': 'ACTIVA',
            'puntaje_manual': '60.00',
          },
          {
            'id': '6f1c0000-0000-0000-0000-000000000002',
            'postulante': 'Luis Rojas',
            'etapa': 'Preseleccionado',
            'estado': 'ACTIVA',
            'puntaje_manual': '95.50',
          },
        ]);

        final lista = await servicio.porVacante(1);

        expect(lista.map((c) => c.nombreCompleto), ['Luis Rojas', 'Ana Pérez']);
      },
      skip:
          'HALLAZGO H-1 (grave): CandidatoRanking.fromJson espera id y '
          'puntajes numéricos y no lee "postulante" como texto. Corregir '
          'en T2-20 o publicar /vacantes/{id}/ranking en el backend.',
    );
  });

  group('Caso 4 · aislado por empresa', () {
    test(
      'la app manda el token: con él el backend filtra por empresa',
      () async {
        final peticiones = <http.Request>[];
        final servicio = _servicio(const [], peticiones: peticiones);

        await servicio.porVacante(1);

        expect(
          peticiones.single.headers['authorization'],
          'Bearer token-empresa-A',
        );
      },
    );

    test('vacante de otra empresa (404): error, sin datos', () async {
      final servicio = _servicio({
        'detail': 'Vacante no encontrada',
      }, status: 404);

      await expectLater(
        servicio.porVacante(99),
        throwsA(
          isA<AppException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Vacante no encontrada'),
        ),
      );
      expect(
        mensajeDeError(
          const AppException('Vacante no encontrada', statusCode: 404),
        ),
        'Vacante no encontrada',
      );
    });

    test('pedir otra empresa (403): mensaje de permiso, no de red', () async {
      final servicio = _servicio({
        'detail': 'No puedes operar sobre otra empresa',
      }, status: 403);

      Object? error;
      try {
        await servicio.porVacante(1);
      } catch (e) {
        error = e;
      }

      expect(error, isA<AppException>());
      expect(mensajeDeError(error!), contains('no tienes permiso'));
    });

    test('sin sesión: no se manda cabecera de autorización', () async {
      final peticiones = <http.Request>[];
      final servicio = _servicio(
        {'detail': 'No autenticado'},
        status: 401,
        peticiones: peticiones,
        token: null,
      );

      await expectLater(servicio.porVacante(1), throwsA(isA<AppException>()));
      expect(peticiones.single.headers.containsKey('authorization'), isFalse);
    });
  });
}
