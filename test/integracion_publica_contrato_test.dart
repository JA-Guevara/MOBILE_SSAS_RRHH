import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/cv_adjunto.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/model/postulante.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service.dart';

const baseUrl = 'https://backend.example/api/v1';

void main() {
  test('CU-09 consulta empresa, lista y detalle con slug y UUID', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/farmacorp')) {
        return http.Response.bytes(utf8.encode(jsonEncode({
          'nombre': 'Farmacorp', 'nombre_comercial': 'Farmacorp',
          'portal_publico_activo': true,
        })), 200);
      }
      final vacante = {
        'id': 'e72ca6a0-43a0-4e27-ad16-8395f78ca6f1',
        'titulo': 'Auxiliar de farmacia', 'descripcion': 'Atención al cliente',
        'requisitos': 'Experiencia', 'modalidad': 'PRESENCIAL',
        'mostrar_salario': false,
      };
      return http.Response.bytes(utf8.encode(jsonEncode(
          request.url.path.endsWith('/vacantes') ? [vacante] : vacante)), 200);
    });
    final service = VacantesService(baseUrl: baseUrl, client: client);
    expect(await service.nombreEmpresa('farmacorp'), 'Farmacorp');
    final lista = await service.vacantesPublicas('farmacorp');
    expect(lista.single.titulo, 'Auxiliar de farmacia');
    expect((await service.obtenerDetalle('farmacorp', lista.single.id)).id, lista.single.id);
    expect(paths, [
      '/api/v1/publico/farmacorp',
      '/api/v1/publico/farmacorp/vacantes',
      '/api/v1/publico/farmacorp/vacantes/e72ca6a0-43a0-4e27-ad16-8395f78ca6f1',
    ]);
    service.close();
  });

  test('CU-10 envía vacante_id y CV al endpoint público real', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/publico/postulaciones');
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('vacante_id'));
      expect(request.body, contains('vacante-uuid'));
      expect(request.body, contains('cv.pdf'));
      return http.Response(jsonEncode({
        'id': 'postulacion-uuid', 'codigo_seguimiento': 'POST-A1B2C3D4',
        'estado': 'ACTIVA', 'fecha_postulacion': '2026-10-04T12:00:00',
      }), 201);
    });
    final service = PostulacionesService(baseUrl: baseUrl, client: client);
    final resultado = await service.postular(
      slug: 'farmacorp', vacanteId: 'vacante-uuid',
      postulante: const Postulante(
        nombres: 'Ana', apellidos: 'Prueba', email: 'ana@example.com',
        ci: '1234567', telefono: '77777777', ciudad: 'Cochabamba',
        nivelEducativo: 'LICENCIATURA', aniosExperiencia: 0,
      ),
      cv: CvAdjunto(nombre: 'cv.pdf', bytes: Uint8List.fromList([37, 80, 68, 70])),
    );
    expect(resultado.codigoSeguimiento, 'POST-A1B2C3D4');
    service.close();
  });

  test('CU-11 muestra estado real y distingue código inexistente', () async {
    final client = MockClient((request) async {
      expect(request.url.path, startsWith('/api/v1/publico/postulaciones/'));
      if (request.url.path.endsWith('/POST-INVALIDO')) return http.Response('', 404);
      return http.Response.bytes(utf8.encode(jsonEncode({
        'codigo_seguimiento': 'POST-A1B2C3D4', 'estado': 'ACTIVA',
        'etapa': 'Postulación', 'vacante': 'Auxiliar de farmacia',
        'fecha_postulacion': '2026-10-04T12:00:00',
        'fecha_ultimo_cambio': '2026-10-04T12:00:00',
      })), 200);
    });
    final service = SeguimientoService(baseUrl: baseUrl, client: client);
    final item = await service.porCodigo('post-a1b2c3d4');
    expect(item?.vacanteTitulo, 'Auxiliar de farmacia');
    expect(item?.etapaActual, 'Postulación');
    expect(item?.etapas, isEmpty);
    expect(await service.porCodigo('POST-INVALIDO'), isNull);
    service.close();
  });
}
