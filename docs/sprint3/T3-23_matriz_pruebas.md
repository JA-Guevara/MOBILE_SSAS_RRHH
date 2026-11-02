# T3-23 · Pruebas del sprint 3 + reporte

Responsable: Ariany Claure · Repos: rrhh-api, rrhh-web, rrhh-movil · HU-13 a HU-17

## Estado del backend al 24/10/2026

En `rrhh-api` (rama `main`, última migración `20261006_0010`) **todavía no
existen** las tablas ni los endpoints de asistencia, nómina, solicitudes de
ausencia, contrato ni documento_empleado (T3-01 a T3-09). Por eso:

- Los casos del **móvil** se probaron de forma automática contra un backend
  simulado (`MockClient`) que usa el JSON del diagrama de clases del sprint 3.
- Los casos del **backend** y de la **web** quedan **pendientes** hasta que
  esos endpoints estén publicados en Railway.

Para repetir las pruebas del móvil:

```bash
flutter test test/sprint3_reglas_test.dart
```

## Matriz de casos

| # | Caso | Repo | Qué se comprueba | Resultado esperado | Resultado obtenido | Estado | Fecha |
|---|---|---|---|---|---|---|---|
| 1a | Boleta contra hoja manual · sueldo Bs 3.500 | móvil | La boleta muestra lo que calculó el backend y cuadra | Ganado Bs 3.500,00 · AFP Bs 444,85 · líquido Bs 3.055,15 | Igual a la hoja; haberes y descuentos suman sus totales | ✅ Pasa | 24/10/2026 |
| 1b | Boleta contra hoja manual · sueldo Bs 9.800 | móvil | Ídem con un segundo sueldo | Ganado Bs 9.800,00 · AFP Bs 1.245,58 · líquido Bs 8.554,42 | Igual a la hoja | ✅ Pasa | 24/10/2026 |
| 1c | Aporte patronal fuera del líquido | móvil | La línea APORTE_PATRONAL no se resta al trabajador | Solo AFP en descuentos | Solo AFP en descuentos | ✅ Pasa | 24/10/2026 |
| 1d | Boleta contra hoja manual (cálculo) | api | T3-09 calcula la boleta con las reglas salariales | Mismos importes que la hoja | — | ⏳ Pendiente: no hay nómina en el backend | — |
| 2a | Cambio de parámetro a mitad de gestión | móvil | Cada boleta enseña el porcentaje de su periodo; la app no recalcula | Julio 12,71 % · agosto 13,21 % | Julio 12,71 % (líquido Bs 3.928,05) · agosto 13,21 % (Bs 3.905,55) | ✅ Pasa | 24/10/2026 |
| 2b | Cambio de parámetro a mitad de gestión | api | Las boletas ya aprobadas no cambian al editar parametro_valor | Julio conserva 12,71 % | — | ⏳ Pendiente: no hay nómina en el backend | — |
| 3a | Marca de entrada desde el móvil | móvil | POST con latitud, longitud, origen `APP_MOVIL` y token | Cuerpo y cabecera correctos | Correctos | ✅ Pasa | 24/10/2026 |
| 3b | Doble marca rechazada | móvil | Un 409 del backend se muestra con su propio mensaje | "Ya registraste tu entrada hoy." | Igual | ✅ Pasa | 24/10/2026 |
| 3c | Doble marca rechazada | api | UNIQUE (empleado_id, fecha) en asistencia | 409 en la segunda marca | — | ⏳ Pendiente: no hay asistencia en el backend | — |
| 4a | Saldo de vacaciones · aviso al jefe | móvil | Si pide más días que su saldo, la tarjeta sale en rojo antes de aprobar | "Pide 5 días: son más de los que tiene." | Igual | ✅ Pasa | 24/10/2026 |
| 4b | Saldo de vacaciones · rechazo del backend | móvil | Un 422 al aprobar se muestra con su motivo | "Saldo insuficiente: tiene 3 días y pide 5." | Igual | ✅ Pasa | 24/10/2026 |
| 4c | Saldo de vacaciones nunca negativo | api | Aprobar no deja dias_saldo < 0 | 422 y saldo intacto | — | ⏳ Pendiente: no hay solicitudes en el backend | — |
| 4d | Saldo de vacaciones nunca negativo | web | La bandeja web muestra el error del backend | Mensaje visible | — | ⏳ Pendiente: depende de 4c | — |

## Hallazgos

| ID | Hallazgo | Dónde | Estado |
|---|---|---|---|
| H-1 | Todos los ids del backend son UUID (texto). Las pantallas del sprint 3 leían el id como número y habrían fallado con el JSON real, igual que el ranking en T2-21. | rrhh-movil | Corregido: los modelos leen el id con `leerId` (`lib/shared/format/json_id.dart`) |
| H-2 | Ningún endpoint devuelve el `empleado_id` del usuario autenticado. Asistencia, boletas, legajo y equipo lo necesitan del token. | rrhh-api | Abierto: hace falta `/empleados/me` o `empleado_id` en `/auth/me` |
| H-3 | El login móvil no envía `empresa_slug`; un empleado no puede iniciar sesión. | rrhh-movil | Abierto |
| H-4 | Los literales de `asistencia.estado`, `boleta_pago.estado` y `solicitud_ausencia.estado` no están definidos en ningún plan. | rrhh-api | Abierto: el móvil los reconoce por prefijo mientras tanto |
