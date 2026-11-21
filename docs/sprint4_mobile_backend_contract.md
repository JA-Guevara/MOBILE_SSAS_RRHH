# Sprint 4 móvil: contratos y configuración

La app usa los endpoints reales de capacitación, habilidades, indicadores y notificaciones. Las notificaciones leídas se guardan en el backend por usuario y empresa.

Para activar FCM en Android o iOS, compilar con `--dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... --dart-define=FIREBASE_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=...`. Los cuatro valores deben corresponder a la aplicación Firebase registrada para el identificador de paquete de la app. La app solicita permiso, llama a `register()` y registra el Firebase Installation ID recibido en `onRegistered` mediante `/notificaciones/dispositivos`. El campo JSON `token` conserva su nombre por compatibilidad, pero contiene un **FID**. Revoca ese identificador y llama a `unregister()` al cerrar sesión. Sin los cuatro valores, mantiene la bandeja por HTTP sin iniciar Firebase. Android e iOS tienen habilitada la opción nativa de Installation ID. iOS requiere además habilitar Push Notifications y APNs en el proyecto Apple y en Firebase; Android requiere los permisos de notificación del dispositivo.

**Contrato de entrega:** `firebase_messaging` 17 entrega un Firebase Installation ID (FID) en `onRegistered`. El emisor backend debe usar `firebase_admin.messaging.Message(fid=...)` con el valor almacenado en el campo `token`. La bandeja HTTP y el registro de dispositivos funcionan independientemente de la entrega push.

El certificado y los materiales protegidos se descargan con el token de sesión y se abren desde almacenamiento local en Android o iOS. Los enlaces externos de lecciones se abren en la aplicación del sistema.
