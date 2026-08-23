import '../../../shared/api/http_client.dart';
import '../../auth/storage/token_storage.dart';

class AuditLog {
  const AuditLog({
    required this.action,
    required this.description,
    this.createdAt,
  });
  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    action: json['action']?.toString() ?? 'Sin acción',
    description: json['description']?.toString() ?? 'Sin descripción',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
  final String action;
  final String description;
  final DateTime? createdAt;
}

class BitacoraApi {
  const BitacoraApi(this._client, this._tokenStorage);
  final AppHttpClient _client;
  final TokenStorage _tokenStorage;

  Future<List<AuditLog>> list({String? search}) async {
    final token = await _tokenStorage.readAccessToken();
    final query = search == null || search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final response = await _client.get('/bitacora$query', accessToken: token);
    final items = response is Map<String, dynamic>
        ? response['items']
        : response;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(AuditLog.fromJson)
        .toList(growable: false);
  }
}
