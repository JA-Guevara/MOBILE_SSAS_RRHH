import 'package:flutter/material.dart';

import '../api/bitacora_api.dart';

class AuditLogCard extends StatelessWidget {
  const AuditLogCard({required this.log, super.key});
  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final date = log.createdAt?.toLocal().toString().split('.').first;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.history)),
        title: Text(log.action),
        subtitle: Text(
          date == null ? log.description : '${log.description}\n$date',
        ),
        isThreeLine: date != null,
      ),
    );
  }
}
