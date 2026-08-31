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
