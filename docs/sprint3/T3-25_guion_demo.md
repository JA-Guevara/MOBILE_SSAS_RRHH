# T3-25 · Demo del Sprint Review 3

Sprint 3 · Personal y Nómina · Duración objetivo: 12 minutos

**Hilo de la demo:** contratar → marcar asistencia → solicitar vacación →
aprobar → calcular nómina → boleta en el móvil.

## Antes de empezar (datos en Railway)

Empresa demo `pollos-kiky-app` con:

| Dato | Para qué paso |
|---|---|
| Usuario **RR. HH.** (rol ADMIN_EMPRESA) | 1, 5 |
| Usuario **jefe** (rol JEFE_AREA) con un empleado a cargo | 4 |
| Postulante **Julia Quispe** en etapa "Oferta" de *Desarrollador Backend* | 1 |
| Cargo *Desarrollador Backend* con banda salarial Bs 8.000 a 11.000 | 1 |
| Tipo de ausencia *Vacación* (descuenta_vacacion = true) y saldo de 15 días para la gestión 2026 | 3, 4 |
| Periodo de nómina *Octubre 2026* en estado ABIERTO | 5 |
| Dos teléfonos o emuladores: uno con la sesión de Julia y otro con la del jefe | 2, 3, 4, 6 |

> **Plan B:** si los endpoints del sprint 3 no están en Railway el día de la
> demo, los pasos móviles se muestran con los servicios falsos (`flutter run`,
> menú *SSAH · Pantallas de prueba*) y los pasos web se explican con capturas.
> Hoy (24/10) el backend todavía no tiene asistencia, nómina ni solicitudes.

## Guion

| # | Quién / dónde | Acción | Qué se dice | Qué se debe ver |
|---|---|---|---|---|
| 1 | RR. HH. · web | Contratar a Julia desde el tablero de selección: cargo, jefe directo, salario Bs 9.800, fecha de inicio | "El postulante pasa a empleado sin volver a cargar sus datos, y el contrato queda versionado." | Julia en la lista de empleados con contrato VIGENTE |
| 2 | Julia · móvil · *Marcar asistencia* (T3-18) | Pulsar **Marcar entrada** y aceptar el permiso de ubicación | "La marca guarda latitud y longitud. Una segunda entrada el mismo día se rechaza." | "Hoy · <hora de la marca> a —:—" y el botón cambia a **Marcar salida** |
| 3 | Julia · web | Solicitar 3 días de vacación | "El sistema valida el saldo antes de enviar." | Solicitud en estado pendiente |
| 4 | Jefe · móvil · *Bandeja del jefe* (T3-22) | Abrir la solicitud, ver el saldo y **Aprobar** con una observación | "El jefe aprueba desde el teléfono y ve si el saldo alcanza antes de decidir." | La solicitud sale de la bandeja; el saldo baja a 12 días |
| 4b | Jefe · móvil · *Equipo a mi cargo* (T3-29) | Abrir la lista | "El jefe ve quién marcó hoy, sin poder editar nada." | Julia con chip **En jornada** |
| 5 | RR. HH. · web | Calcular la nómina de Octubre 2026 y aprobar el periodo | "Las reglas salariales calculan haberes, descuentos y aportes." | Boleta de Julia: ganado Bs 9.800,00 · AFP Bs 1.245,58 · líquido Bs 8.554,42 |
| 6 | Julia · móvil · *Mis boletas* (T3-20) | Abrir la boleta de octubre | "El colaborador ve su boleta con el detalle de haberes y descuentos." | Los mismos importes del paso 5 |
| 6b | Julia · móvil · *Mi legajo digital* (T3-27) | Abrir el legajo | "La app avisa de los documentos por vencer." | Aviso en ámbar o rojo arriba de la lista |

## Cierre (1 minuto)

- Pruebas del sprint: matriz en `docs/sprint3/T3-23_matriz_pruebas.md`
  (8 casos del móvil en verde; los del backend pendientes de T3-05 a T3-09).
- Lo que falta para el sprint 4: el endpoint de "mi empleado" (H-2) y el
  `empresa_slug` en el login móvil (H-3).
