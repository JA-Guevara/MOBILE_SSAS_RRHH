import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../api/auth_api.dart';
import '../storage/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authApi, this._tokenStorage);
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;
  bool isLoading = false;
  String? errorMessage;
  String? userName;

  Future<bool> login({required String email, required String password}) =>
      _run(() async {
        final session = await _authApi.login(email: email, password: password);
        await _tokenStorage.saveAccessToken(session.accessToken);
        userName = session.userName ?? email.split('@').first;
      });

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) => _run(
    () => _authApi.register(name: name, email: email, password: password),
  );

  Future<void> logout() async {
    await _tokenStorage.clear();
    userName = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() operation) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
