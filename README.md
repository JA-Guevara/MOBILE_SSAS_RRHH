# mobile_ssas_rrhh

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# MOBILE_SSAS_RRHH

---

## Cómo tomar capturas

Las capturas de pantalla son la evidencia de las tareas. Todas se toman
contra **servicios falsos**: el backend todavía no tiene estos endpoints, así
que no hace falta ni internet ni iniciar sesión.

### El comando

```bash
flutter run -d chrome
```

Con la app abierta en Chrome, cada vez que guardes `lib/main.dart` pulsa `r`
en la terminal (*hot reload*) para ver el cambio sin reiniciar.

> Si prefieres una ventana de escritorio en vez del navegador:
> `flutter run -d windows`. Las dos valen como evidencia.

### Los dos pasos de siempre

Todo se controla desde `lib/main.dart`:

1. **Qué pantalla arranca** → en `main()`, descomenta UNA línea del bloque
   `MODO · con qué pantalla arranca la app`.
2. **Qué estado de esa pantalla** → baja hasta el bloque `MODO` de esa
   pantalla y descomenta UNA línea del servicio.

Cada pantalla vive en su propia función y su servicio se construye solo
cuando la eliges, así que puedes comentar los bloques que no uses sin romper
la compilación.

### Qué cambiar para cada estado

| Pantalla | `const pantalla =` | Estado | Servicio a descomentar |
|---|---|---|---|
| **Portal de vacantes** (T1-18) | `Pantalla.portal` | Con datos | `VacantesServiceFalso()` |
| | | Vacía | `VacantesServiceVacio()` |
| | | Con error | `VacantesServiceError()` |
| **Postulación** (T1-20) | `Pantalla.portal` | Éxito + código | `PostulacionesServiceFalso()` |
| | *(toca una vacante)* | Con error | `PostulacionesServiceError()` |
| | | Validación 422 | `PostulacionesServiceValidacion()` |

| **Asistencia con GPS** (T3-18) | `Pantalla.asistencia` | Sin marcar | `AsistenciaServiceSinMarcar()` |
| | | Con entrada | `AsistenciaServiceConEntrada()` |
| | | Día completo | `AsistenciaServiceDiaCompleto()` |
| | | Con error | `AsistenciaServiceError()` |
| | *(grupo permiso)* | Concedido / denegado / a ajustes / GPS apagado | `UbicacionServiceFalso()` / `UbicacionServiceDenegada()` / `UbicacionServiceDenegadaPermanente()` / `UbicacionServiceSinGps()` |
| **Mis boletas** (T3-20) | `Pantalla.boletas` | Con boletas | `BoletasServiceFalso()` |
| | *(toca una boleta)* | Vacía | `BoletasServiceVacio()` |
| | | Con error | `BoletasServiceError()` |
| **Bandeja del jefe** (T3-22) | `Pantalla.aprobaciones` | Con pendientes | `AprobacionesServiceFalso()` |
| | *(toca una solicitud)* | Vacía | `AprobacionesServiceVacio()` |
| | | Con error | `AprobacionesServiceError()` |
| | | Sesión expirada | `AprobacionesServiceSinSesion()` |
| **Mi legajo digital** (T3-27) | `Pantalla.legajo` | Con documentos y avisos | `LegajoServiceFalso()` |
| | | Vacío | `LegajoServiceVacio()` |
| | | Con error | `LegajoServiceError()` |
| | | Sesión expirada | `LegajoServiceSinSesion()` |
| **Equipo a mi cargo** (T3-29) | `Pantalla.equipo` | Con equipo | `EquipoServiceFalso()` |
| | | Nadie a cargo | `EquipoServiceVacio()` |
| | | Con error | `EquipoServiceError()` |
| | | No es jefe (403) | `EquipoServiceSinPermiso()` |

> Seguimiento (T2-18), entrevista (T2-19) y ranking (T2-20) tienen sus
> estados en su bloque MODO de `lib/main.dart`.
>
> **Sprint 3:** el backend todavía no tiene asistencia, nómina, solicitudes,
> contratos ni documentos, así que estas cinco pantallas van SOLO con
> servicios falsos. Las rutas que usarán están marcadas en cada servicio
> con `>>> VERIFICA esta ruta en /docs <<<`.

### Notas

- **Portal** y **Asistencia** tienen DOS grupos de opciones dentro de su
  bloque MODO (portal: vacantes y postulación; asistencia: el día y el
  permiso de ubicación). Elige una línea de cada grupo.
- El estado **cargando** se ve durante el primer segundo: los servicios
  falsos simulan la demora de la red a propósito.
- Si eliges una pantalla cuyo bloque MODO está comentado, la app no se cae:
  muestra un aviso en ámbar diciendo cuál falta.

### Comprobaciones antes de entregar

```bash
flutter analyze
```

Solo deben salir **7 issues**, todos de `lib/core/api/` (código generado por
OpenAPI: no se toca, se pierde al regenerar).

```bash
flutter test
```

Falla únicamente `test/app_test.dart`, que ya venía roto de antes. La prueba
`test/main_pantallas_test.dart` comprueba que la app arranca con **cada**
valor del enum `Pantalla`.
