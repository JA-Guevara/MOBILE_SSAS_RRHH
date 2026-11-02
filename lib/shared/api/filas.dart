/// Las filas de una respuesta de lista.
///
/// El backend puede devolver la lista directa o envuelta en
/// {"items": [...]} / {"data": [...]}, igual que en las otras features.
/// Cualquier otra cosa se toma como lista vacía.
List<Map<String, dynamic>> filasDe(Object? respuesta) {
  final items = respuesta is Map<String, dynamic>
      ? (respuesta['items'] ?? respuesta['data'])
      : respuesta;
  if (items is! List) return const [];
  return items.whereType<Map<String, dynamic>>().toList();
}
