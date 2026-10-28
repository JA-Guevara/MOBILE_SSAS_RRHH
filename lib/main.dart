import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/aprobaciones/ui/bandeja_page.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/ubicacion_service.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/data/ubicacion_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/asistencia/ui/asistencia_page.dart';
import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/boletas/ui/boletas_page.dart';
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/equipo/ui/equipo_page.dart';
import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/legajo/ui/legajo_page.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/mi_contrato/ui/mi_contrato_page.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/data/mis_dias_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/mis_dias/ui/mis_dias_page.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/solicitudes/ui/solicitar_ausencia_page.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/ui/tipos_ausencia_page.dart';
// Los servicios REALES del Sprint 3. Los usan las líneas "BACKEND REAL"
// comentadas de cada bloque MODO; se quedan aunque ahora no se lean.
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/aprobaciones/data/aprobaciones_service.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/asistencia/data/asistencia_service.dart';
import 'package:mobile_ssas_rrhh/features/auth/storage/token_storage.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/boletas/data/boletas_service.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/equipo/data/equipo_service.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/legajo/data/legajo_service.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/mi_contrato/data/mi_contrato_service.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/mis_dias/data/mis_dias_service.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/solicitudes/data/solicitudes_service.dart';
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/tipos_ausencia/data/tipos_ausencia_service.dart';
import 'package:mobile_ssas_rrhh/shared/api/http_client.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/data/entrevista_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/entrevista/ui/consulta_entrevista_page.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service.dart';
// Lo usan las líneas comentadas del bloque MODO del portal.
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/ranking/data/ranking_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/ranking/ui/ranking_page.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/data/seguimiento_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/seguimiento/ui/consulta_codigo_page.dart';
// Lo usan las líneas comentadas del bloque MODO del portal (las capturas
// VACÍA y CON ERROR). Se queda aunque ahora mismo no se lea.
// ignore: unused_import
import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service_falso.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/ui/vacantes_publicas_page.dart';
import 'package:mobile_ssas_rrhh/features/vacantes/data/vacantes_service.dart';

/// ARCHIVO DE PRUEBA para ver cada pantalla y sacar las capturas de
/// evidencia. No es la app de producción: aquí todo va contra servicios
/// FALSOS, porque el backend todavía no tiene estos endpoints.
///
/// CÓMO USARLO:
///   1. Elige la pantalla en el bloque MODO de más abajo (UNA línea).
///   2. Elige el estado dentro del bloque MODO de esa pantalla.
///   3. Ejecuta:  flutter run -d chrome
///
/// Ver la sección "Cómo tomar capturas" del README.
///
/// CÓMO ESTÁ ARMADO (y por qué):
///   Cada pantalla se construye en SU PROPIA función, y su servicio se crea
///   dentro de ella. Solo se ejecuta la función de la pantalla elegida, así
///   que los servicios de las demás ni se construyen. Eso significa que
///   puedes comentar el bloque MODO que quieras sin romper nada: ninguna
///   otra pantalla lee sus variables.
///
///   Aquí viven el Sprint 1 (T1-18 y T1-20), el Sprint 2 (T2-18, T2-19 y
///   T2-20) y el Sprint 3 (T3-18, T3-19, T3-20, T3-21, T3-22, T3-27,
///   T3-28, T3-29 y T3-30). Cada
///   pantalla nueva añade tres cosas: su valor al enum [Pantalla], su línea
///   al mapa [pantallas] y su bloque MODO. Nada más.
void main() {
  // ============ MODO · con qué pantalla arranca la app =============
  // CAMBIA SOLO ESTA LÍNEA. Descomenta UNA:

  const pantalla = Pantalla.menu; // TODAS: menú para elegir cualquiera
  // const pantalla = Pantalla.seguimiento; // T2-18
  // const pantalla = Pantalla.ranking;     // T2-20
  // const pantalla = Pantalla.entrevista;  // T2-19
  // const pantalla = Pantalla.portal;      // T1-18 y T1-20
  // const pantalla = Pantalla.asistencia;  // T3-18
  // const pantalla = Pantalla.misDias;     // T3-21
  // const pantalla = Pantalla.boletas;     // T3-20
  // const pantalla = Pantalla.solicitud;   // T3-19
  // const pantalla = Pantalla.aprobaciones; // T3-22
  // const pantalla = Pantalla.legajo;      // T3-27
  // const pantalla = Pantalla.miContrato;  // T3-28
  // const pantalla = Pantalla.equipo;      // T3-29
  // const pantalla = Pantalla.tiposAusencia; // T3-30

  // =================================================================

  runApp(const AppSSAH(pantalla: pantalla));
}

/// Con qué pantalla arranca la app de prueba.
enum Pantalla {
  menu,
  portal,
  seguimiento,
  ranking,
  entrevista,
  asistencia,
  misDias,
  boletas,
  solicitud,
  aprobaciones,
  legajo,
  miContrato,
  equipo,
  tiposAusencia,
}

/// Qué función construye cada pantalla.
///
/// Es un Map y no un `switch` a propósito: si comentas un bloque MODO y su
/// línea de aquí, el archivo SIGUE COMPILANDO. Al arrancar esa pantalla
/// verías el aviso de [_PantallaNoConfigurada] en vez de una lista de
/// errores del compilador.
///
/// El precio de esa comodidad es que el compilador ya no te obliga a añadir
/// la pantalla cuando amplías el enum. De eso se encarga
/// test/main_pantallas_test.dart, que recorre `Pantalla.values` y comprueba
/// que todas están aquí y que todas se dibujan.
final Map<Pantalla, Widget Function()> pantallas = {
  Pantalla.menu: _menu,
  Pantalla.portal: _portal,
  Pantalla.seguimiento: _seguimiento,
  Pantalla.ranking: _ranking,
  Pantalla.entrevista: _entrevista,
  Pantalla.asistencia: _asistencia,
  Pantalla.misDias: _misDias,
  Pantalla.boletas: _boletas,
  Pantalla.solicitud: _solicitud,
  Pantalla.aprobaciones: _aprobaciones,
  Pantalla.legajo: _legajo,
  Pantalla.miContrato: _miContrato,
  Pantalla.equipo: _equipo,
  Pantalla.tiposAusencia: _tiposAusencia,
};

class AppSSAH extends StatelessWidget {
  final Pantalla pantalla;

  const AppSSAH({super.key, this.pantalla = Pantalla.portal});

  @override
  Widget build(BuildContext context) {
    // La pantalla se construye AQUÍ, no en main(): solo la elegida.
    final construir = pantallas[pantalla];

    return MaterialApp(
      title: 'SSAH · RR. HH.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: construir == null
          ? _PantallaNoConfigurada(pantalla: pantalla)
          : construir(),
    );
  }
}

// ===================================================================
//  Un bloque MODO por pantalla. Cada uno es independiente: sus
//  variables viven dentro de su función y nadie de fuera las lee.
// ===================================================================

/// ====== MODO · portal de vacantes y postulación (T1-18 y T1-20) ======
/// Toca una tarjeta de vacante para abrir el formulario de postulación.
/// Descomenta UNA sola línea de cada grupo:
Widget _portal() {
  final servicio = VacantesService(baseUrl: _apiUrl); // BACKEND REAL
  // final servicio = VacantesServiceFalso();   // captura 1: CON DATOS
  // final servicio = VacantesServiceVacio();   // captura 2: VACÍA
  // final servicio = VacantesServiceError();   // captura 3: CON ERROR

  // --- el formulario de postulación (T1-20) ---
  final servicioPostulacion = PostulacionesService(baseUrl: _apiUrl); // REAL
  // final servicioPostulacion = PostulacionesServiceFalso(); // ÉXITO + código
  // final servicioPostulacion = PostulacionesServiceError();      // CON ERROR
  // final servicioPostulacion = PostulacionesServiceValidacion();  // 422

  return _ElegirEmpresa(
    service: servicio,
    postulacionesService: servicioPostulacion,
  );
}

const _apiUrl = 'https://backendssasrrhh-production.up.railway.app/api/v1';

/// Pide el código (slug) de la empresa y abre su portal de vacantes.
class _ElegirEmpresa extends StatefulWidget {
  final VacantesService service;
  final PostulacionesService postulacionesService;

  const _ElegirEmpresa({
    required this.service,
    required this.postulacionesService,
  });

  @override
  State<_ElegirEmpresa> createState() => _ElegirEmpresaState();
}

class _ElegirEmpresaState extends State<_ElegirEmpresa> {
  final _slug = TextEditingController(text: 'pollos-kiky-app');
  var _buscando = false;
  String? _error;

  @override
  void dispose() {
    _slug.dispose();
    super.dispose();
  }

  Future<void> _abrir() async {
    final slug = _slug.text.trim().toLowerCase();
    if (slug.isEmpty) return;
    setState(() {
      _buscando = true;
      _error = null;
    });
    try {
      final nombre = await widget.service.nombreEmpresa(slug);
      if (!mounted) return;
      setState(() => _buscando = false);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VacantesPublicasPage(
            slug: slug,
            empresaNombre: nombre,
            service: widget.service,
            postulacionesService: widget.postulacionesService,
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portal de empleos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Escribe el código de la empresa para ver sus vacantes.',
            style: TextStyle(color: AppColors.tinta2, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slug,
            enabled: !_buscando,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _abrir(),
            decoration: InputDecoration(
              labelText: 'Código de la empresa',
              hintText: 'ej. pollos-kiky-app',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _buscando ? null : _abrir,
            child: _buscando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ver vacantes'),
          ),
        ],
      ),
    );
  }
}

/// ========= MODO · línea de tiempo de la postulación (T2-18) ======
/// Descomenta UNA sola línea:
Widget _seguimiento() {
  final servicio = SeguimientoServiceFalso(); // CON DATOS
  // final servicio = SeguimientoServiceVacio();  // CÓDIGO NO EXISTE
  // final servicio = SeguimientoServiceError();  // CON ERROR

  return ConsultaCodigoPage(
    service: servicio,
    // Precargado para no tener que teclearlo en cada captura.
    codigoInicial: 'TX-8F4K2',
  );
}

/// ============ MODO · ranking del reclutador (T2-20) ==============
/// Descomenta UNA sola línea:
Widget _ranking() {
  final servicio = RankingServiceFalso(); // CON DATOS
  // final servicio = RankingServiceVacio();      // SIN POSTULANTES
  // final servicio = RankingServiceError();      // CON ERROR
  // final servicio = RankingServiceSinSesion();  // SESIÓN EXPIRADA

  return RankingPage(
    vacanteId: 1,
    vacanteTitulo: 'Desarrollador Backend',
    service: servicio,
  );
}

/// ========= MODO · confirmar entrevista desde el móvil (T2-19) =========
/// El backend todavía no tiene entrevistas (T2-02): solo servicios falsos.
/// Descomenta UNA sola línea:
Widget _entrevista() {
  final servicio = EntrevistaServiceFalso(); // POR CONFIRMAR (virtual)
  // final servicio = EntrevistaServicePresencial();        // POR CONFIRMAR (presencial)
  // final servicio = EntrevistaServiceConfirmada();        // YA CONFIRMADA
  // final servicio = EntrevistaServiceVacio();             // SIN ENTREVISTA
  // final servicio = EntrevistaServiceError();             // CON ERROR
  // final servicio = EntrevistaServiceErrorAlConfirmar();  // FALLA AL CONFIRMAR

  return ConsultaEntrevistaPage(
    service: servicio,
    // Formato real del backend, precargado para las capturas.
    codigoInicial: 'POST-8F4K2A1C',
  );
}

/// ========= MODO · marcar asistencia con GPS (T3-18) ===============
/// El backend todavía no tiene asistencia (T3-05). Cuando la tenga,
/// descomenta la línea BACKEND REAL y comenta las demás del grupo "el día".
/// Esta pantalla tiene DOS grupos: el día y el permiso de ubicación.
/// Descomenta UNA sola línea de cada grupo:
Widget _asistencia() {
  // --- el día ---
  // final servicio = AsistenciaService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = AsistenciaServiceSinMarcar(); // —:— a —:—
  // final servicio = AsistenciaServiceConEntrada();  // 08:03 a —:—
  // final servicio = AsistenciaServiceDiaCompleto(); // BOTÓN CERRADO
  // final servicio = AsistenciaServiceError();       // CON ERROR

  // --- el permiso ---
  // El tipo se escribe a mano (y no `final`) para que la última opción, la
  // del GPS de verdad, siga siendo válida al descomentarla.
  const UbicacionService ubicacion = UbicacionServiceFalso(); // CONCEDIDO
  // const ubicacion = UbicacionServiceDenegada();            // DENEGADO
  // const ubicacion = UbicacionServiceDenegadaPermanente();  // A AJUSTES
  // const ubicacion = UbicacionServiceSinGps();              // GPS APAGADO
  // const ubicacion = UbicacionService();  // el GPS de verdad, en el teléfono

  return AsistenciaPage(service: servicio, ubicacion: ubicacion);
}

/// ===== MODO · mis días trabajados y saldo de vacaciones (T3-21) =====
/// El backend todavía no tiene asistencia (T3-05) ni saldo_vacacion
/// (T3-06): solo servicios falsos. Las marcas falsas se arman hasta hoy.
/// Descomenta UNA sola línea:
Widget _misDias() {
  // final servicio = MisDiasService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = MisDiasServiceFalso(); // CON DÍAS
  // final servicio = MisDiasServiceVacio();      // MES SIN MARCAS
  // final servicio = MisDiasServiceSinSaldo();   // SIN SALDO
  // final servicio = MisDiasServiceError();      // CON ERROR
  // final servicio = MisDiasServiceSinSesion();  // SESIÓN EXPIRADA

  return MisDiasPage(service: servicio);
}

/// ============= MODO · mis boletas de pago (T3-20) ================
/// El backend todavía no tiene nómina (T3-09): solo servicios falsos.
/// Toca una boleta para abrir su detalle. Descomenta UNA sola línea:
Widget _boletas() {
  // final servicio = BoletasService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = BoletasServiceFalso(); // CON BOLETAS
  // final servicio = BoletasServiceVacio();  // SIN BOLETAS
  // final servicio = BoletasServiceError();  // CON ERROR

  return BoletasPage(service: servicio);
}

/// ======== MODO · solicitar permiso o vacaciones (T3-19) ===========
/// El backend todavía no tiene tipo_ausencia, saldo_vacacion ni
/// solicitud_ausencia (T3-06): solo servicios falsos.
/// Descomenta UNA sola línea:
Widget _solicitud() {
  // final servicio = SolicitudesService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = SolicitudesServiceFalso(); // FORMULARIO (saldo de 3 días)
  // final servicio = SolicitudesServiceSinSaldo();  // SIN SALDO
  // final servicio = SolicitudesServiceVacio();     // SIN TIPOS
  // final servicio = SolicitudesServiceError();     // CON ERROR
  // final servicio = SolicitudesServiceSinSesion(); // SESIÓN EXPIRADA
  // final servicio = SolicitudesServiceErrorAlEnviar(); // FALLA AL ENVIAR

  return SolicitarAusenciaPage(service: servicio);
}

/// ============ MODO · bandeja del jefe (T3-22) ====================
/// El backend todavía no tiene solicitudes (T3-06): solo servicios falsos.
/// Toca una solicitud para abrir el detalle y responderla.
/// Descomenta UNA sola línea:
Widget _aprobaciones() {
  // final servicio = AprobacionesService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = AprobacionesServiceFalso(); // CON PENDIENTES
  // final servicio = AprobacionesServiceVacio();     // VACÍA
  // final servicio = AprobacionesServiceError();     // CON ERROR
  // final servicio = AprobacionesServiceSinSesion(); // 401

  return BandejaPage(service: servicio);
}

/// ============== MODO · mi legajo digital (T3-27) =================
/// El backend todavía no tiene documento_empleado (T3-02): solo servicios
/// falsos. Descomenta UNA sola línea:
Widget _legajo() {
  // final servicio = LegajoService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = LegajoServiceFalso(); // CON DOCUMENTOS (y avisos)
  // final servicio = LegajoServiceVacio();      // SIN DOCUMENTOS
  // final servicio = LegajoServiceError();      // CON ERROR
  // final servicio = LegajoServiceSinSesion();  // SESIÓN EXPIRADA

  return LegajoPage(service: servicio);
}

/// ================ MODO · mi contrato vigente (T3-28) ===============
/// El backend todavía no tiene contrato (T3-03): solo servicios falsos.
/// Descomenta UNA sola línea:
Widget _miContrato() {
  // final servicio = MiContratoService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = MiContratoServiceFalso(); // VIGENTE + HISTORIAL
  // final servicio = MiContratoServicePrimerContrato(); // SIN HISTORIAL
  // final servicio = MiContratoServiceFinalizado();     // SIN VIGENTE
  // final servicio = MiContratoServiceVacio();          // SIN CONTRATOS
  // final servicio = MiContratoServiceError();          // CON ERROR
  // final servicio = MiContratoServiceSinSesion();      // SESIÓN EXPIRADA

  return MiContratoPage(service: servicio);
}

/// ============== MODO · equipo a mi cargo (T3-29) =================
/// El backend todavía no tiene contrato ni asistencia (T3-01, T3-05):
/// solo servicios falsos. Descomenta UNA sola línea:
Widget _equipo() {
  // final servicio = EquipoService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = EquipoServiceFalso(); // CON EQUIPO
  // final servicio = EquipoServiceVacio();       // NADIE A CARGO
  // final servicio = EquipoServiceError();       // CON ERROR
  // final servicio = EquipoServiceSinPermiso();  // NO ES JEFE (403)

  return EquipoPage(service: servicio);
}

/// ========= MODO · configurar tipos de ausencia (T3-30) ============
/// El backend ya tiene GET /personal/tipos-ausencia, pero solo con los
/// activos y sin las ocho columnas, y todavía no tiene cómo guardar:
/// solo servicios falsos. Toca un tipo para editarlo; lo guardado se ve al
/// volver a la lista. Descomenta UNA sola línea:
Widget _tiposAusencia() {
  // final servicio = TiposAusenciaService(backendReal(), sesionReal()); // BACKEND REAL
  final servicio = TiposAusenciaServiceFalso(); // CON TIPOS (uno inactivo)
  // final servicio = TiposAusenciaServiceVacio();         // SIN TIPOS
  // final servicio = TiposAusenciaServiceError();         // CON ERROR
  // final servicio = TiposAusenciaServiceErrorAlGuardar(); // FALLA AL GUARDAR
  // final servicio = TiposAusenciaServiceSinSesion();     // SESIÓN EXPIRADA
  // final servicio = TiposAusenciaServiceSinPermiso();    // NO ES ADMIN (403)

  return TiposAusenciaPage(service: servicio);
}

/// El cliente del backend de verdad para las líneas "BACKEND REAL" del
/// Sprint 3: la misma URL que el portal.
AppHttpClient backendReal() => AppHttpClient(baseUrl: _apiUrl);

/// El token que guardó el login en el almacenamiento seguro.
TokenStorage sesionReal() => const SecureTokenStorage();

/// ============== MODO · menú con todas las pantallas ===============
/// Abre cualquier pantalla con un toque y vuelve aquí con "atrás".
/// El estado de cada una (con datos, vacía, error...) se sigue eligiendo
/// en su propio bloque MODO.
Widget _menu() => const _MenuPantallas();

/// Título que se ve en el menú para cada pantalla.
const _titulosMenu = {
  Pantalla.portal: ('Portal de vacantes y postulación', 'T1-18 · T1-20'),
  Pantalla.seguimiento: ('Seguimiento de postulación', 'T2-18'),
  Pantalla.ranking: ('Ranking del reclutador', 'T2-20'),
  Pantalla.entrevista: ('Confirmar entrevista', 'T2-19'),
  Pantalla.asistencia: ('Marcar asistencia con GPS', 'T3-18'),
  Pantalla.misDias: ('Mis días trabajados y saldo de vacaciones', 'T3-21'),
  Pantalla.boletas: ('Mis boletas de pago', 'T3-20'),
  Pantalla.solicitud: ('Solicitar permiso o vacaciones', 'T3-19'),
  Pantalla.aprobaciones: ('Bandeja del jefe: aprobar o rechazar', 'T3-22'),
  Pantalla.legajo: ('Mi legajo digital', 'T3-27'),
  Pantalla.miContrato: ('Mi contrato vigente', 'T3-28'),
  Pantalla.equipo: ('Equipo a mi cargo', 'T3-29'),
  Pantalla.tiposAusencia: ('Configurar tipos de ausencia', 'T3-30'),
};

class _MenuPantallas extends StatelessWidget {
  const _MenuPantallas();

  @override
  Widget build(BuildContext context) {
    final opciones = Pantalla.values.where((p) => p != Pantalla.menu);

    return Scaffold(
      appBar: AppBar(title: const Text('SSAH · Pantallas de prueba')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in opciones)
            Card(
              child: ListTile(
                title: Text(_titulosMenu[p]?.$1 ?? p.name),
                subtitle: Text(_titulosMenu[p]?.$2 ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        pantallas[p]?.call() ??
                        _PantallaNoConfigurada(pantalla: p),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lo que se ve si eliges una pantalla cuyo bloque MODO está comentado.
///
/// Existe para que comentar un bloque sea un aviso claro en pantalla y no
/// una lista de errores de compilación.
class _PantallaNoConfigurada extends StatelessWidget {
  final Pantalla pantalla;

  const _PantallaNoConfigurada({required this.pantalla});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.ambar100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_outlined,
                  color: AppColors.ambar700,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'La pantalla "${pantalla.name}" no está configurada.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.tinta, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Su bloque MODO está comentado en lib/main.dart, o le falta '
                'la línea del mapa "pantallas".',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.tinta2, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
