import 'package:flutter/material.dart';

class AuditLogFilters extends StatelessWidget {
  const AuditLogFilters({required this.onSearch, super.key});
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => TextField(
    decoration: const InputDecoration(
      labelText: 'Buscar en la bitácora',
      prefixIcon: Icon(Icons.search),
    ),
    textInputAction: TextInputAction.search,
    onSubmitted: onSearch,
  );
}
