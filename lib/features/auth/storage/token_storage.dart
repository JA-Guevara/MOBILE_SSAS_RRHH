abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clear();
}

class MemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  @override
  Future<String?> readAccessToken() async => _accessToken;
  @override
  Future<void> saveAccessToken(String token) async => _accessToken = token;
  @override
  Future<void> clear() async => _accessToken = null;
}
