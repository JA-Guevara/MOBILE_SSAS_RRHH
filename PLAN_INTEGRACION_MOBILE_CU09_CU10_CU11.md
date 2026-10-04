# Plan de integración móvil: CU-09, CU-10 y CU-11

## Objetivo

Entregar una app Flutter que consulte vacantes reales de una empresa, permita postular con CV y consulte el estado mediante el código devuelto por el backend de Railway. El recorrido normal no debe mostrar datos simulados. Se trabaja en este repositorio móvil; esta fase no cambia el backend ni la web.

## Alcance de este primer entregable

| Caso | Función móvil | Resultado verificable |
| --- | --- | --- |
| CU-09 | Listar vacantes públicas y abrir el detalle | La vacante publicada en la web aparece en la app, con sus datos reales. |
| CU-10 | Enviar postulación pública con CV | El backend responde 201 y la app muestra el código de seguimiento real. |
| CU-11 | Consultar el estado con ese código | La app muestra estado, etapa, vacante y fechas que devuelve el backend. |

No incluye login, ranking, confirmación de entrevistas, nómina, cursos, chatbot ni una línea de tiempo histórica detallada. Esa línea de tiempo corresponde a Sprint 2 y no debe inventarse a partir del estado actual.

## Contrato verificado en el backend local

Base de producción prevista: `https://backendssasrrhh-production-7c33.up.railway.app/api/v1`. Confirmar que sigue siendo el dominio activo antes de distribuir la APK. No incorporar claves secretas ni tokens en el código o en `--dart-define`.

| Acción | Método y ruta | Datos importantes |
| --- | --- | --- |
| Empresa pública | `GET /publico/{empresa_slug}` | Nombre comercial y estado del portal. |
| Vacantes | `GET /publico/{empresa_slug}/vacantes` | Lista directa de vacantes publicadas y vigentes; admite filtros opcionales `ubicacion` y `modalidad`. |
| Detalle | `GET /publico/{empresa_slug}/vacantes/{vacante_id}` | Una vacante, identificada por UUID. |
| Postulación | `POST /publico/postulaciones` | `multipart/form-data`; `vacante_id` viaja como campo, no en la ruta. |
| Seguimiento | `GET /publico/postulaciones/{codigo}` | Devuelve `codigo_seguimiento`, `estado`, `etapa`, `vacante`, `fecha_postulacion` y `fecha_ultimo_cambio`. |

La postulación exige `vacante_id`, `nombres`, `apellidos`, `ci`, `email`, `telefono`, `ciudad`, `nivel_educativo`, `anios_experiencia` y `cv`; `linkedin` es opcional. Los valores aceptados de `nivel_educativo` son `SECUNDARIA`, `TECNICO`, `LICENCIATURA`, `MAESTRIA` y `DOCTORADO`. El CV debe ser PDF o DOCX y no superar 5 MB. La respuesta exitosa contiene `id`, `codigo_seguimiento`, `estado` y `fecha_postulacion`. El código generado actualmente tiene formato `POST-` seguido de ocho caracteres hexadecimales; la app debe tratarlo como dato del servidor, no fabricarlo ni imponer el formato antiguo `TX-`.

**Fuentes del contrato:** `../BACKEND_SSAH_RRHH/src/ssas/vacantes/infrastructure/http/router.py`, `schemas.py` del mismo módulo, `../BACKEND_SSAH_RRHH/src/ssas/postulaciones/infrastructure/http/router.py`, `schemas.py` del mismo módulo y `application/use_cases/crear_postulacion_publica.py`. Antes de implementar, contrastar con `/openapi.json` de la versión efectivamente desplegada en Railway; el checkout local y el deploy pueden diferir.

## Trabajo propuesto

### 1. Configuración y arranque

- Definir una sola base URL por entorno, con valor local para desarrollo y URL HTTPS de Railway para la APK. Evitar las tres direcciones actuales dispersas en `lib/core/constants/app_constants.dart`, `lib/shared/network/api_client.dart` y `lib/main.dart`.
- Definir el `empresa_slug` real como configuración de la experiencia pública; no usar el valor de muestra `1234`. Verificar el slug con la empresa publicada, sin asumir que coincide con el código de login.
- Hacer que `lib/main.dart` arranque en la experiencia pública real. Conservar el menú y los servicios `*Falso` solo para tests o una compilación de demostración explícita; jamás como ruta normal de la APK.
- Agregar permiso de Internet al manifiesto principal de Android. No depender únicamente de los manifiestos `debug` y `profile`.

### 2. CU-09: vacantes y detalle

- Corregir `VacantesService` para construir la URL desde `baseUrl` y `empresa_slug`, sin dirección fija y sin llamadas a la raíz del servidor.
- Ajustar `Vacante.fromJson` al esquema real y comprobar fechas, salario opcional, modalidad y datos faltantes. Mostrar salario solo cuando `mostrar_salario` sea verdadero.
- Hacer que el detalle consulte su endpoint real. Actualmente `VacanteDetalleScreen` utiliza `VacantesServiceFalso`; debe recibir el servicio real o la vacante seleccionada según convenga al diseño existente.
- Conservar los estados cargando, lista vacía, error y reintento. Una falla de red no debe presentarse como lista vacía.

**Aceptación:** publicar una vacante desde la web, verla en el móvil, abrir su detalle y constatar título, modalidad, ubicación, descripción y requisitos iguales a los de la web.

### 3. CU-10: postulación con CV

- Corregir `PostulacionesService` para enviar `POST /publico/postulaciones`, con `vacante_id` y los demás campos requeridos en el multipart. Mantener `cv` como parte de archivo.
- Hacer obligatorios en la interfaz `ci`, `telefono`, `ciudad`, `nivel_educativo` y `anios_experiencia` (puede ser 0). Enviar los valores enumerados del backend, aunque la etiqueta visible tenga tildes y formato amigable. Eliminar `Universitario en curso` como valor enviado si no existe equivalencia aprobada.
- Mantener validación de PDF/DOCX y 5 MB antes del envío y respetar los errores 400/409/422/503 del servidor. Evitar reenvíos accidentales mientras la petición está en curso.
- Incluir una aceptación explícita del uso de datos personales, coherente con el formulario público web. No inventar un campo API de consentimiento si el backend no lo acepta; verificar cómo queda documentada esa aceptación antes de darla por cerrada.
- Mostrar el código devuelto, ofrecer copiarlo y abrir CU-11 con ese mismo código. No sustituirlo por un valor de ejemplo.

**Aceptación:** postular una persona ficticia con un CV válido desde el móvil; obtener HTTP 201 y el código; verificar que la postulación aparece en la web. Repetir con el mismo candidato y vacante para comprobar el error de duplicado sin crear otra postulación.

### 4. CU-11: consulta por código

- Enlazar el botón de seguimiento del portal con `ConsultaCodigoPage` y `SeguimientoService` reales. `MiPostulacionScreen` usa otro servicio falso y no debe seguir siendo la entrada normal.
- Ajustar la validación al código `POST-...` real; no rechazar un código válido por el patrón `TX-XXXXX` de la maqueta. Codificar el código al construir la URL.
- Adaptar el modelo y la pantalla a los seis campos que devuelve hoy el backend. El modelo actual supone un ID numérico, empresa, puntajes, notas y una lista de etapas que no están en esa respuesta; no mostrar valores inventados ni una línea de tiempo falsa.
- Manejar código inexistente (404), error de red y reintento. No exponer datos de otra postulación ni guardar el código en registros de diagnóstico.

**Aceptación:** consultar el código obtenido en CU-10 y ver la misma vacante, etapa y estado que en la web; un código inventado debe mostrar un estado de no encontrado, no una postulación simulada.

## Pruebas mínimas

1. Unitarias de URL y deserialización con respuestas reales de ejemplo: lista, detalle, postulación 201 y seguimiento 200/404.
2. Widget tests de estados cargando, vacío, error, validación de campos, CV inválido y éxito con código.
3. Integración en un teléfono Android contra Railway: vacante publicada -> detalle -> postulación ficticia -> código -> seguimiento -> comprobación en web.
4. Comprobación de aislamiento por empresa: un slug no debe mostrar vacantes de otra empresa.
5. Verificación de release APK con Internet, HTTPS y URL de Railway; no basta con que funcione en el emulador o en Chrome.

No usar datos personales reales en las pruebas. Registrar capturas de estados vacío, con datos y error según la evidencia del plan de sprints.

## Orden de entrega y criterio de cierre

- **PR 1:** configuración, arranque real y CU-09.
- **PR 2:** CU-10 y carga de CV.
- **PR 3:** CU-11 y recorrido completo en dispositivo.

Cada PR incluye pruebas de su contrato y no introduce cambios en backend ni web. El entregable está completo únicamente cuando los tres CU funcionan juntos contra Railway desde una APK de prueba y la postulación se observa también en la web. Generar o publicar la APK definitiva es una decisión posterior; primero debe pasar este recorrido integral.
