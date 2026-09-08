import 'package:flutter/material.dart';

import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';
import 'package:mobile_ssas_rrhh/features/postulaciones/data/postulaciones_service_falso.dart';
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
///   En esta rama solo vive el Sprint 1 (T1-18 y T1-20). Las pantallas de
///   los sprints 2, 3 y 4 llegan en sus propios PR, y cada una añade tres
///   cosas: su valor al enum [Pantalla], su línea al mapa [pantallas] y su
///   bloque MODO. Nada más.
void main() {
  // ============ MODO · con qué pantalla arranca la app =============
  // CAMBIA SOLO ESTA LÍNEA. Descomenta UNA:

  const pantalla = Pantalla.portal; //       T1-18 y T1-20

  // =================================================================

  runApp(const AppSSAH(pantalla: pantalla));
}

/// Con qué pantalla arranca la app de prueba.
enum Pantalla { portal }

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
  Pantalla.portal: _portal,
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
  // --- la lista de vacantes (T1-18) ---
  final servicio = VacantesServiceFalso(); // captura 1: CON DATOS
  // final servicio = VacantesServiceVacio();   // captura 2: VACÍA
  // final servicio = VacantesServiceError();   // captura 3: CON ERROR

  // --- el formulario de postulación (T1-20) ---
  final servicioPostulacion = PostulacionesServiceFalso(); // ÉXITO + código
  // final servicioPostulacion = PostulacionesServiceError();      // CON ERROR
  // final servicioPostulacion = PostulacionesServiceValidacion();  // 422

  // ¡AQUÍ ESTABA EL ERROR! Faltaba el return y el punto y coma al final.
  // Nota: Le quité la barra diagonal (/) al final de la URL para evitar que 
  // la ruta se construya con doble barra (ej. .app//publico/...)
  return VacantesPublicasPage(
    slug: '1234',
    empresaNombre: 'Pollos Kiky S.R.L.',
    service: VacantesService(baseUrl: 'https://backendssasrrhh-production.up.railway.app/api/v1'), 
    postulacionesService: PostulacionesServiceFalso(),
  );
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
