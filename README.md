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
> contratos ni documentos, así que estas cinco pantallas arrancan con
> servicios falsos. Cuando el backend esté listo, en cada bloque MODO se
> descomenta la línea `BACKEND REAL` y listo: no hay que tocar nada más.

### Sprint 3: qué espera la app del backend

Los servicios falsos **no reemplazan código**: le pasan al servicio real un
backend de mentira (`lib/shared/api/backend_falso.dart`) que responde por
HTTP con filas de las tablas del diagrama del Sprint 3. Las pantallas
corren el mismo código que correrá contra rrhh-api.

Cada modelo lee **solo las columnas de su tabla** y la app une las tablas
por sus llaves (`periodo_id`, `boleta_id`, `tipo_ausencia_id`,
`empleado_id`, `cargo_id`). Por eso el backend solo tiene que devolver las
filas tal cual, sin objetos anidados.

| Ruta (prefijo `/api/v1`) | Devuelve | Pantalla |
|---|---|---|
| `GET /asistencias/hoy` | una fila de `asistencia` (404 si no marcó) | T3-18 |
| `POST /asistencias/entrada` · body `latitud_entrada`, `longitud_entrada`, `origen` | la fila de `asistencia` | T3-18 |
| `POST /asistencias/salida` · body `latitud_salida`, `longitud_salida` | la fila de `asistencia` | T3-18 |
| `GET /boletas` | filas de `boleta_pago` del colaborador | T3-20 |
| `GET /boletas/{id}` | una fila de `boleta_pago` | T3-20 |
| `GET /boletas/{id}/detalles` | filas de `boleta_detalle` | T3-20 |
| `GET /periodos-nomina` | filas de `periodo_nomina` | T3-20 |
| `GET /solicitudes-ausencia/pendientes` | filas de `solicitud_ausencia` del jefe | T3-22 |
| `GET /solicitudes-ausencia/{id}` | una fila de `solicitud_ausencia` | T3-22 |
| `POST /solicitudes-ausencia/{id}/aprobar` y `/rechazar` · body `observacion_aprobador` | la fila actualizada | T3-22 |
| `GET /tipos-ausencia` | filas de `tipo_ausencia` | T3-22 |
| `GET /saldos-vacacion[?empleado_id=]` | filas de `saldo_vacacion` | T3-22 |
| `GET /documentos-empleado/mios` | filas de `documento_empleado` del colaborador | T3-27 |
| `GET /contratos/mi-equipo` | filas de `contrato` cuyo `jefe_directo_id` es el usuario | T3-29 |
| `GET /asistencias?fecha=AAAA-MM-DD` | filas de `asistencia` del equipo ese día | T3-29 |
| `GET /empleados`, `GET /cargos` | **ya existen**: solo para mostrar nombres | T3-22, T3-29 |

Ninguna ruta manda `empleado_id` ni `aprobador_id`: el backend los saca del
token. Si alguna ruta queda distinta, se cambia una línea en el servicio
(están marcadas con `>>> VERIFICA esta ruta en /docs <<<`).

Para que los servicios reales funcionen, además, el login tiene que guardar
el token de verdad en el almacenamiento seguro con la clave `access_token`
(hoy guarda uno falso) y enviar `empresa_slug`.

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
