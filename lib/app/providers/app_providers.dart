import 'package:flutter/widgets.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/api/auth_api.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/storage/token_storage.dart';
import '../../features/bitacora/api/bitacora_api.dart';
import '../../shared/api/http_client.dart';

class AppProviders extends StatefulWidget {
  const AppProviders({required this.child, super.key});
  final Widget child;

  static AppDependencies of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(result != null, 'AppProviders no está disponible en el árbol.');
    return result!;
  }

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late final AppHttpClient _httpClient;
  late final AuthProvider _auth;
  late final BitacoraApi _bitacoraApi;

  @override
  void initState() {
    super.initState();
    final tokenStorage = MemoryTokenStorage();
    _httpClient = AppHttpClient(baseUrl: AppConstants.apiBaseUrl);
    _auth = AuthProvider(AuthApi(_httpClient), tokenStorage);
    _bitacoraApi = BitacoraApi(_httpClient, tokenStorage);
  }

  @override
  void dispose() {
    _auth.dispose();
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDependencies(
    auth: _auth,
    bitacoraApi: _bitacoraApi,
    child: widget.child,
  );
}

class AppDependencies extends InheritedNotifier<AuthProvider> {
  const AppDependencies({
    required this.auth,
    required this.bitacoraApi,
    required super.child,
    super.key,
  }) : super(notifier: auth);

  final AuthProvider auth;
  final BitacoraApi bitacoraApi;
}
