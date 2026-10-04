# mobile_ssas_rrhh

## Portal público real (CU-09, CU-10 y CU-11)

La app abre el portal público conectado al backend. Si no se define `EMPRESA_SLUG`, pide el slug de la empresa al iniciar. Para una compilación de prueba con una empresa fija:

```bash
flutter run --dart-define=EMPRESA_SLUG=<slug-del-portal>
```

La API usa por defecto `https://backendssasrrhh-production-7c33.up.railway.app/api/v1`. Para otro entorno:

```bash
flutter run --dart-define=API_BASE_URL=https://tu-backend/api/v1 --dart-define=EMPRESA_SLUG=<slug-del-portal>
```

El slug es la parte de la URL pública de empleos que identifica a la empresa; no es el código de inicio de sesión. No pongas claves secretas ni tokens en `--dart-define`. Antes de distribuir una APK, verificar que el backend y el slug sean los correctos, ejecutar `flutter analyze` y `flutter test`, probar postulación y seguimiento en un teléfono y configurar la firma Android de publicación.

Los servicios falsos siguen disponibles únicamente para pruebas y capturas de demostración. El menú de demostración se activa explícitamente con `--dart-define=DEMO_MODE=true`; no es el arranque normal de la app.

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

## Capturas con servicios falsos (modo demo)

Este modo conserva las pantallas y servicios falsos de las pruebas originales.
No representa el funcionamiento de la app conectada a Railway.

### El comando

```bash
flutter run -d chrome --dart-define=DEMO_MODE=true
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

> **Esta rama solo trae el Sprint 1.** Las pantallas de los sprints 2, 3 y 4
> (seguimiento, ranking, asistencia, boletas, aprobaciones, cursos y chatbot)
> llegan en sus propios PR, y cada una añadirá su fila a esta tabla.

### Notas

- **Portal** tiene DOS grupos de opciones dentro de su bloque MODO: la lista
  de vacantes y el formulario de postulación. Elige una línea de cada grupo.
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
