import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class MySkillsPage extends StatefulWidget {
  const MySkillsPage({required this.api, super.key});
  final StaffApi api;
  @override
  State<MySkillsPage> createState() => _MySkillsPageState();
}

class _MySkillsPageState extends State<MySkillsPage> {
  late Future<List<Map<String, dynamic>>> _data = widget.api.mySkills();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis habilidades')),
    body: FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No se pudieron cargar las habilidades: ${snapshot.error}',
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _data = widget.api.mySkills()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final skills = snapshot.data!;
        if (skills.isEmpty) {
          return const Center(
            child: Text('Aún no tienes habilidades registradas.'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _data = widget.api.mySkills());
            await _data;
          },
          child: ListView.builder(
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text('${skill['habilidad_nombre']}'),
                subtitle: Text(
                  [
                    if (skill['nivel'] != null) 'Nivel: ${skill['nivel']}',
                    if (skill['curso_titulo'] != null)
                      'Curso: ${skill['curso_titulo']}',
                    if (skill['adquirida_en'] != null)
                      'Adquirida: ${skill['adquirida_en']}',
                  ].join(' · '),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
