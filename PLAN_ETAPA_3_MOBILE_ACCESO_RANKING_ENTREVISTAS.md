# Etapa 3 mobile: acceso real y Sprint 2

## Objetivo y límites

Integrar en el repositorio mobile existente el acceso real de personal autorizado (CU-03) y el ranking de candidatos (CU-14), sin alterar el portal público ya implementado (CU-09, CU-10 y CU-11). Para completar CU-15 se añadirá una API pública segura en **nuestro backend conectado a Railway** y después se conectará mobile. No se modifica la web ni se trabaja en `grupo/main`.

Este documento es un plan de trabajo, no una afirmación de que la Etapa 3 ya está hecha. Antes de implementarlo, contrastar el contrato del checkout local con `/openapi.json` de Railway.

## Avance de implementación local

- CU-03: la entrada normal del mobile tiene login real de empresa o plataforma, sesión en almacenamiento seguro, renovación, perfil/permisos y cierre de sesión. El login simulado anterior ya no es la entrada de la app.
- CU-14: hay selección de vacante, ranking real, orden, filtro de estado y paginación. Falta comprobarlo con una cuenta autorizada de Railway.
- CU-15: por decisión del usuario, la consulta y confirmación usan solo el código de seguimiento. El backend devuelve datos mínimos y audita la confirmación; el mobile llama a esas rutas. **Todavía no está desplegado ni comprobado de extremo a extremo.** Quien conozca el código podrá ver o confirmar la entrevista.
- No se ejecutaron análisis ni pruebas automáticas por pedido del usuario. Quedan pendientes las pruebas de concurrencia y seguridad de CU-15, `flutter analyze`, `flutter test` y la prueba en teléfono.
- Antes de usar CU-15 en Railway: desplegar este backend y comprobar que el estado se refleja en la web. No requiere SMTP ni una migración nueva.

## Estado real hoy

| Área | Estado en mobile | Qué corregir |
| --- | --- | --- |
| Inicio normal | `lib/main.dart` abre el portal público real. El menú con servicios falsos solo se usa con `DEMO_MODE=true`. | Mantener el portal público accesible sin login. |
| Login | `lib/features/auth/screens/login_screen.dart` espera 2 segundos y acepta `admin`/`1234`; guarda tokens inventados. No está integrado en el inicio normal. | Reemplazar por autenticación de Railway, sin credenciales ni tokens de muestra. |
| Infraestructura de auth | Existen `AuthApi`, `AuthProvider` y `AppProviders`, pero `AuthApi` envía solo `email`/`password`, `AppProviders` usa `MemoryTokenStorage` y el login simulado usa otro almacenamiento. | Unificar flujo, contrato, almacenamiento y navegación. No conservar dos sesiones paralelas. |
| Ranking | `RankingService` apunta a `/vacantes/{id}/ranking`, ruta que **sí existe** localmente; el modelo usa ID `int` y campos de respuesta supuestos. | Adaptar a UUID, `empresa_id` cuando corresponda y `RankingResponse` real. |
| Entrevistas del postulante | `EntrevistaService` usa rutas públicas propuestas por mobile. No se encontraron en el backend local. | Diseñar e implementar primero el contrato seguro en nuestro backend; después conectar mobile. No mostrar una confirmación falsa. |

**Importante:** una persona que se postula no necesita cuenta para CU-09 a CU-11. CU-03 es el acceso del personal/reclutador. El código de seguimiento no es un token de acceso interno.

## Contrato backend identificado

Base de API: `https://backendssasrrhh-production-7c33.up.railway.app/api/v1` (configurable mediante `API_BASE_URL`). La empresa pública predeterminada del mobile es `2222`, pero el usuario puede cambiarla; para el login empresarial se debe enviar el slug de la empresa elegida o solicitado expresamente al usuario, no asumirlo a partir del nombre mostrado.

| Uso | Ruta | Contrato relevante |
| --- | --- | --- |
| Iniciar sesión | `POST /auth/login` | JSON con `password` y `email` **o** `username`; `empresa_slug` presente para usuario de empresa, omitido para cuenta de plataforma. Devuelve `access_token`, `refresh_token`, `token_type`, `expires_in` y `must_change_password`. |
| Renovar sesión | `POST /auth/refresh` | Recibe `refresh_token`; devuelve un par nuevo y revoca el anterior. |
| Cerrar sesión | `POST /auth/logout` | Requiere bearer de acceso y `refresh_token` en el cuerpo; revoca el refresh token. |
| Perfil y permisos | `GET /auth/me` | Requiere bearer; devuelve identidad, `empresa_id`, roles, permisos efectivos, módulos y estado de seguridad. |
| Ranking | `GET /vacantes/{id}/ranking` | `id` es UUID; bearer con `postulaciones:ver`; admite `empresa_id` para alcance autorizado, `estado`, `orden` (`ia`, `manual`, `evaluaciones`, `entrevistas`), `offset` y `limit`. Devuelve `{items, total}`. |
| Entrevistas internas | `GET /entrevistas` y `PATCH /entrevistas/{id}/estado` | Son rutas de selección para usuarios autenticados y permisos. **No equivalen** a consulta/confirmación pública del postulante. |

En el backend local no se encontraron `GET /publico/postulaciones/{codigo}/entrevista` ni `POST /publico/postulaciones/{codigo}/entrevista/confirmar`. El servicio mobile que las llama es un prototipo. Verificar el despliegue antes de concluir que siguen ausentes en producción; no inventar respuestas cuando devuelvan 404.

Fuentes locales: `../BACKEND_SSAH_RRHH/src/ssas/auth/infrastructure/http/router.py`, `schemas.py`, `../BACKEND_SSAH_RRHH/src/ssas/postulaciones/infrastructure/http/seleccion_router.py` y `seleccion_schemas.py`.

## Orden de implementación

### 1. CU-03: autenticación real

1. Mantener una entrada pública para vacantes y ofrecer una entrada separada para personal. La pantalla de login debe aceptar código/slug de empresa y correo **o** usuario, además de contraseña. Para cuenta de plataforma, ofrecer un modo explícito que omita `empresa_slug`.
2. Sustituir el `Future.delayed`, `admin`/`1234` y los tokens `token_generico_*` por `POST /auth/login`. Usar una sola capa `AuthApi`/`AuthProvider` y un único almacenamiento seguro persistente en Android. No poner claves ni contraseñas en el repositorio, registros o capturas.
3. Guardar access y refresh token; al abrir la app, intentar restaurar/renovar la sesión y consultar `/auth/me`. Usar `empresa_id`, permisos y módulos devueltos por el servidor para mostrar las funciones internas. No deducir permisos decodificando el token en el cliente.
4. Ante 401, renovar una sola vez mediante `/auth/refresh`, guardar el par nuevo de forma consistente y reintentar la petición original una sola vez. Si falla, borrar credenciales locales y volver al login. Tratar por separado 403, 423, 429, 503 y falta de red; respetar `must_change_password` y no habilitar funciones internas mientras esté pendiente.
5. En cierre de sesión, llamar `/auth/logout` con bearer y refresh token, limpiar siempre el almacenamiento local y volver al portal público. No usar solo `deleteAll()` como sustituto de la revocación remota.
6. Quitar el acceso a la pantalla simulada de cualquier recorrido normal. Los servicios `*Falso` pueden quedar exclusivamente en pruebas o `DEMO_MODE=true`.

**Aceptación:** iniciar con una cuenta real de empresa, reiniciar la app y restaurar la sesión; comprobar `/auth/me`, renovación y cierre; verificar que una cuenta sin permiso no vea ranking y que no haya tokens inventados ni credenciales de muestra activas.

### 2. CU-14: ranking del reclutador

1. Pedir la lista de vacantes de selección de la empresa autorizada; no exigir que el reclutador escriba un UUID manualmente.
2. Adaptar `RankingService` para usar el access token del flujo anterior, UUID y respuesta `{items, total}`. Mapear `id`, `nombre_postulante`, `experiencia_anios`, `educacion`, `estado`, `puntaje_ia`, `puntaje_manual`, `puntaje_evaluaciones`, `puntaje_entrevistas`, habilidades, entrevistas y evaluaciones; tolerar puntajes `null` sin fabricar porcentajes.
3. Dejar que el backend aplique `orden`, filtros y paginación. No reordenar localmente por IA si el usuario eligió otro criterio. Solo mostrar opciones que los permisos efectivos permitan; manejar 401/403 y ausencia de resultados sin exponer candidatos de otra empresa.

**Aceptación:** el reclutador ve las mismas postulaciones y puntajes autorizados que en la web para una vacante real; filtros, orden y paginación coinciden con la API; otra empresa no accede a esos datos.

### 3. CU-15: API segura y conexión de entrevistas del postulante

1. Contrastar primero el OpenAPI de Railway. Si las rutas siguen ausentes, añadirlas **solo en nuestro repositorio backend** y desplegarlas en Railway antes de conectar la pantalla mobile. Las rutas internas de selección no se harán públicas ni se reutilizarán sin sus permisos.
2. Definir el contrato público mínimo: consultar la próxima entrevista futura asociada a una postulación y confirmar la asistencia. La respuesta solo contiene fecha, hora, modalidad, lugar o enlace y estado; no expone evaluaciones, notas ni datos internos del entrevistador.
3. Por decisión del usuario, usar el código de seguimiento como única credencial para estas rutas. No se envía correo. Esto facilita las pruebas, pero cualquiera que obtenga el código podrá ver y confirmar la entrevista. No compartir códigos públicamente ni registrarlos en logs.
4. Confirmar únicamente la entrevista de la postulación indicada, futura y en estado `PROGRAMADA`; impedir dobles confirmaciones y auditar el cambio. Probar aislamiento entre postulaciones.
5. Agregar pruebas de backend para código inexistente, entrevista cancelada, solicitud repetida, aislamiento y concurrencia. Desplegar y comprobar las rutas con datos ficticios.

**Orden de este bloque:** implementación y pruebas en nuestro backend -> despliegue a Railway -> integración mobile -> comprobación en web del estado final. No se modifica `grupo/main`.

**Aceptación:** solo marcar CU-15 completo si una persona con el código de seguimiento puede consultar y confirmar una entrevista real desde mobile y el nuevo estado se refleja en la web. Una pantalla con datos falsos no cuenta como cumplimiento.

## Pruebas y entregables

- Pruebas de contrato con cliente HTTP falso: login empresarial/plataforma, 401/403/423, refresh, logout, `/auth/me`, ranking `{items, total}` con UUID y puntajes nulos, y CU-15 con código de seguimiento.
- Pruebas de widgets: entrada pública sin login, login/cierre, carga y error, menú por permisos, ranking vacío/con datos/denegado y entrevista real con código de seguimiento.
- Prueba manual en Android contra Railway con cuentas y postulaciones ficticias; nunca registrar tokens ni CV reales en evidencias.
- La Etapa 3 se divide en entregables verificables: **A. CU-03**, **B. CU-14**, **C. API segura de CU-15 en nuestro backend**, **D. CU-15 en mobile**. No declarar toda la etapa terminada porque A o B funcionen.
- No generar APK definitiva ni cambiar la web o `grupo/main`. El único cambio de servidor previsto es la API de CU-15 en nuestro backend Railway. La firma y distribución pertenecen a la Etapa 4.
