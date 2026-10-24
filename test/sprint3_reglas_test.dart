import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mobile_ssas_rrhh/core/errors/app_exception.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/model/saldo_vacacion.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/widgets/tarjeta_saldo.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_detalle.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/boleta_pago.dart';
import 'package:mobile_ssas_rrhh/features/boletas/model/periodo_nomina.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/shared/format/moneda.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';

/// T3-23 · Pruebas del sprint 3 (lado móvil).
///
/// Casos de la tarea y qué le toca a la app en cada uno:
///   1. Boleta contra hoja de verificación manual (2 sueldos distintos)
///        -> la app muestra EXACTAMENTE lo que calculó el backend: los
///           haberes suman el total ganado, los descuentos el total de
///           descuentos, y el líquido coincide con la hoja manual
///   2. Cambio de parámetro a mitad de gestión
///        -> la app no tiene porcentajes fijos: cada boleta enseña el que
///           trae su propia línea
///   3. Doble marca de asistencia rechazada
///        -> la regla es del backend (UNIQUE empleado+fecha); la app manda
///           la marca con sus coordenadas y enseña el 409 tal cual
///   4. Saldo de vacaciones nunca negativo
///        -> la regla es del backend; la app avisa al jefe ANTES de aprobar
///           si el saldo no alcanza, y enseña el rechazo del backend
///
/// El backend todavía no tiene asistencia, nómina ni solicitudes, así que
/// aquí el "backend" es un MockClient con el JSON del diagrama de clases.
/// Cuando rrhh-api publique los endpoints, estos casos se repiten contra
/// Railway y el resultado va a la matriz del reporte.

/// Un servicio real con un backend simulado: responde [cuerpo] con
/// [status] y guarda la petición en [peticiones].
AppHttpClient _cliente(
  Object? cuerpo, {
  int status = 200,
  List<http.Request>? peticiones,
}) {
  final mock = MockClient((req) async {
    peticiones?.add(req);
    return http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), status);
  });
  return AppHttpClient(baseUrl: 'https://api.test/api/v1', client: mock);
}

Future<TokenStorage> _sesion() async {
  final storage = MemoryTokenStorage();
  await storage.saveAccessToken('token-colaborador');
  return storage;
}

/// Una boleta como la devolvería el backend: tres respuestas separadas,
/// una por tabla del diagrama (boleta_pago, boleta_detalle y
/// periodo_nomina). AFP laboral sobre el total ganado; el aporte patronal
/// va en su propia línea y NO es un descuento del trabajador.
typedef _Boleta = ({
  Map<String, dynamic> fila,
  List<Map<String, dynamic>> detalles,
  Map<String, dynamic> periodo,
});

_Boleta _boleta({
  required String id,
  required double basico,
  required double porcentajeAfp,
  required String mes,
}) {
  final afp = double.parse((basico * porcentajeAfp / 100).toStringAsFixed(2));
  final patronal = double.parse((basico * 0.1671).toStringAsFixed(2));
  return (
    fila: {
      'id': id,
      'periodo_id': 'p-$mes',
      'numero': 'BP-$id',
      'salario_basico': basico,
      'total_ganado': basico,
      'total_descuentos': afp,
      'liquido_pagable': double.parse((basico - afp).toStringAsFixed(2)),
      'total_aportes_patronales': patronal,
      'estado': 'APROBADA',
    },
    detalles: [
      {
        'id': '$id-1',
        'boleta_id': id,
        'codigo': 'BASICO',
        'nombre': 'Haber básico',
        'tipo': 'HABER',
        'secuencia': 1,
        'monto': basico,
      },
      {
        'id': '$id-2',
        'boleta_id': id,
        'codigo': 'AFP',
        'nombre': 'AFP laboral',
        'tipo': 'DESCUENTO',
        'secuencia': 10,
        'base': basico,
        'porcentaje': porcentajeAfp,
        'monto': afp,
      },
      {
        'id': '$id-3',
        'boleta_id': id,
        'codigo': 'AP_PAT',
        'nombre': 'Aporte patronal',
        'tipo': 'APORTE_PATRONAL',
        'secuencia': 20,
        'base': basico,
        'porcentaje': 16.71,
        'monto': patronal,
      },
    ],
    periodo: {'id': 'p-$mes', 'nombre': '$mes 2026', 'gestion': 2026},
  );
}

/// Lo que haría BoletasService al unir las tres tablas, sin pasar por HTTP.
BoletaPago _unida(_Boleta b) => BoletaPago.fromJson(b.fila).conRelaciones(
  periodo: PeriodoNomina.fromJson(b.periodo),
  detalles: b.detalles.map(BoletaDetalle.fromJson).toList(),
);

/// Un backend simulado que responde cada tabla en su ruta.
AppHttpClient _backendBoleta(_Boleta b) => AppHttpClient(
  baseUrl: 'https://api.test/api/v1',
  client: MockClient((req) async {
    final id = b.fila['id'];
    final cuerpo = switch (req.url.path) {
      '/api/v1/periodos-nomina' => [b.periodo],
      final r when r == '/api/v1/boletas/$id' => b.fila,
      final r when r == '/api/v1/boletas/$id/detalles' => b.detalles,
      _ => throw StateError('ruta inesperada ${req.url}'),
    };
    return http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), 200);
  }),
);

double _suma(Iterable<double?> montos) =>
    montos.fold(0.0, (total, m) => total + (m ?? 0));

void main() {
  group('Caso 1 · boleta contra la hoja de verificación manual', () {
    // La hoja manual, calculada a mano con 12,71 % de AFP laboral:
    //   sueldo     AFP        líquido
    //   3.500,00   444,85     3.055,15
    //   9.800,00   1.245,58   8.554,42
    const hoja = {
      '3500': ('Bs 3.500,00', 'Bs 444,85', 'Bs 3.055,15'),
      '9800': ('Bs 9.800,00', 'Bs 1.245,58', 'Bs 8.554,42'),
    };

    for (final MapEntry(key: sueldo, value: esperado) in hoja.entries) {
      test('sueldo de Bs $sueldo: coincide con la hoja', () async {
        final servicio = BoletasService(
          _backendBoleta(
            _boleta(
              id: '7c0e2a4b-$sueldo',
              basico: double.parse(sueldo),
              porcentajeAfp: 12.71,
              mes: 'Septiembre',
            ),
          ),
          await _sesion(),
        );

        final boleta = await servicio.detalle('7c0e2a4b-$sueldo');
        expect(boleta.etiquetaPeriodo, 'Septiembre 2026');

        // Lo que ve el colaborador es lo de la hoja manual.
        expect(Moneda.bs(boleta.totalGanado), esperado.$1);
        expect(Moneda.bs(boleta.totalDescuentos), esperado.$2);
        expect(Moneda.bs(boleta.liquidoPagable), esperado.$3);

        // Y la boleta cuadra consigo misma: las líneas suman los totales.
        expect(
          _suma(boleta.haberes.map((d) => d.monto)),
          closeTo(boleta.totalGanado!, 0.005),
        );
        expect(
          _suma(boleta.descuentos.map((d) => d.monto)),
          closeTo(boleta.totalDescuentos!, 0.005),
        );
        expect(
          boleta.totalGanado! - boleta.totalDescuentos!,
          closeTo(boleta.liquidoPagable!, 0.005),
        );
      });
    }

    test('el aporte patronal no se resta del líquido del trabajador', () {
      final boleta = _unida(
        _boleta(id: 'b1', basico: 3500, porcentajeAfp: 12.71, mes: 'Julio'),
      );
      expect(boleta.descuentos.map((d) => d.codigo), ['AFP']);
      expect(boleta.otras.map((d) => d.codigo), ['AP_PAT']);
    });
  });

  group('Caso 2 · cambio de parámetro a mitad de gestión', () {
    test('cada boleta enseña el porcentaje de su propio periodo', () {
      // Julio con 12,71 %; en agosto la empresa cambió el parámetro.
      final julio = _unida(
        _boleta(id: 'j', basico: 4500, porcentajeAfp: 12.71, mes: 'Julio'),
      );
      final agosto = _unida(
        _boleta(id: 'a', basico: 4500, porcentajeAfp: 13.21, mes: 'Agosto'),
      );

      expect(julio.descuentos.single.calculo, '12,71% sobre Bs 4.500,00');
      expect(agosto.descuentos.single.calculo, '13,21% sobre Bs 4.500,00');
      // Con el mismo sueldo, el líquido cambia: la app no recalcula nada.
      expect(Moneda.bs(julio.liquidoPagable), 'Bs 3.928,05');
      expect(Moneda.bs(agosto.liquidoPagable), 'Bs 3.905,55');
    });
  });

  group('Caso 3 · doble marca de asistencia rechazada', () {
    test('la entrada viaja con coordenadas, origen y token', () async {
      final peticiones = <http.Request>[];
      final servicio = AsistenciaService(
        _cliente({
          'id': 'a1',
          'fecha': '2026-10-24',
          'hora_entrada': '08:03:00',
        }, peticiones: peticiones),
        await _sesion(),
      );

      await servicio.marcarEntrada(latitud: -17.7833, longitud: -63.1821);

      final req = peticiones.single;
      expect(req.url.path, '/api/v1/asistencias/entrada');
      expect(req.headers['authorization'], 'Bearer token-colaborador');
      expect(jsonDecode(req.body), {
        'latitud_entrada': -17.7833,
        'longitud_entrada': -63.1821,
        'origen': 'APP_MOVIL',
      });
    });

    test(
      'la segunda entrada del día: 409 con el mensaje del backend',
      () async {
        final servicio = AsistenciaService(
          _cliente({'detail': 'Ya registraste tu entrada hoy.'}, status: 409),
          await _sesion(),
        );

        await expectLater(
          servicio.marcarEntrada(latitud: -17.78, longitud: -63.18),
          throwsA(
            isA<AppException>().having((e) => e.statusCode, 'status', 409),
          ),
        );

        try {
          await servicio.marcarEntrada(latitud: -17.78, longitud: -63.18);
        } on AppException catch (e) {
          expect(mensajeDeErrorAsistencia(e), 'Ya registraste tu entrada hoy.');
        }
      },
    );
  });

  group('Caso 4 · saldo de vacaciones nunca negativo', () {
    const saldo = SaldoVacacion(
      id: 's1',
      gestion: 2026,
      diasAsignados: 15,
      diasUsados: 12,
      diasSaldo: 3,
    );

    test('el saldo alcanza solo hasta llegar a cero', () {
      expect(saldo.alcanzaPara(3), isTrue);
      expect(saldo.alcanzaPara(2.5), isTrue);
      expect(saldo.alcanzaPara(3.5), isFalse);
      expect(saldo.alcanzaPara(5), isFalse);
    });

    testWidgets('el jefe ve el aviso en rojo antes de aprobar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: TarjetaSaldo(saldo: saldo, diasSolicitados: 5),
          ),
        ),
      );
      expect(
        find.text('Pide 5 días: son más de los que tiene.'),
        findsOneWidget,
      );
    });

    test('si el backend rechaza la aprobación, se ve su motivo', () async {
      final servicio = AprobacionesService(
        _cliente({
          'detail': 'Saldo insuficiente: tiene 3 días y pide 5.',
        }, status: 422),
        await _sesion(),
      );

      try {
        await servicio.aprobar('41');
        fail('Debía lanzar AppException');
      } on AppException catch (e) {
        expect(e.statusCode, 422);
        expect(
          mensajeDeErrorAprobaciones(e),
          'Saldo insuficiente: tiene 3 días y pide 5.',
        );
      }
    });
  });
}
