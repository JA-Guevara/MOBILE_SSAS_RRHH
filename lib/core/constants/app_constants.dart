abstract final class AppConstants {
  static const appName = 'SSAS RRHH';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backendssasrrhh-production-7c33.up.railway.app/api/v1',
  );
  static const empresaSlug = String.fromEnvironment(
    'EMPRESA_SLUG',
    defaultValue: '2222',
  );
  static const demoMode = bool.fromEnvironment('DEMO_MODE');
}
