import 'package:flutter/material.dart';
import '../model/vacante.dart';
import '../data/vacantes_service_falso.dart'; 
// Ajusta las rutas de los imports según dónde hayas guardado la pantalla

class VacanteDetalleScreen extends StatefulWidget {
  // 1. CORRECCIÓN: El ID ahora es String (UUID)
  final String vacanteId; 
  final VoidCallback onPostular;

  const VacanteDetalleScreen({
    super.key, 
    required this.vacanteId,
    required this.onPostular,
  });
  @override
  State<VacanteDetalleScreen> createState() => _VacanteDetalleScreenState();
}

class _VacanteDetalleScreenState extends State<VacanteDetalleScreen> {
  final Color primaryDarkGreen = const Color(0xFF0D4A22);
  final Color accentLightGreen = const Color(0xFFD4E7C5);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  bool _isApplying = false;

  Future<Vacante> _fetchVacanteDetalle() async {
    // Nota: Si usas el servicio falso aún, asegúrate de que reciba un String.
    // Si ya cambiaste al real, usa tu nuevo VacantesService aquí.
    return await VacantesServiceFalso().obtenerDetalle(widget.vacanteId);
  }

  void _postular() async {
    setState(() => _isApplying = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isApplying = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Postulación enviada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  // 3. CORRECCIÓN: Función auxiliar para armar el texto del salario
  String _formatearSalario(double? min, double? max) {
    if (min != null && max != null) return 'Bs. ${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}';
    if (min != null) return 'A partir de Bs. ${min.toStringAsFixed(0)}';
    if (max != null) return 'Hasta Bs. ${max.toStringAsFixed(0)}';
    return 'Salario a convenir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryDarkGreen,
        elevation: 0,
        title: const Text('Detalle de Vacante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: FutureBuilder<Vacante>(
        future: _fetchVacanteDetalle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryDarkGreen));
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar la vacante.'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Vacante no encontrada.'));
          }

          final vacante = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vacante.titulo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Text(vacante.subtitulo, style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (vacante.fechaCierreCorta.isNotEmpty)
                        Text(
                          'Cierra el ${vacante.fechaCierreCorta}',
                          style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600),
                        ),
                      
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Divider()),

                      if (vacante.descripcion != null && vacante.descripcion!.trim().isNotEmpty) ...[
                        _buildSectionTitle('Descripción del Puesto'),
                        Text(vacante.descripcion!, style: const TextStyle(color: Colors.black54, height: 1.5, fontSize: 16)),
                        const SizedBox(height: 24),
                      ],

                      // 2. CORRECCIÓN: Separamos el bloque de texto por saltos de línea (\n)
                      if (vacante.requisitos != null && vacante.requisitos!.trim().isNotEmpty) ...[
                        _buildSectionTitle('Requisitos'),
                        ...vacante.requisitos!.split('\n')
                            .where((req) => req.trim().isNotEmpty)
                            .map((req) => _buildBulletPoint(req.trim())),
                        const SizedBox(height: 24),
                      ],

                      if (vacante.beneficios != null && vacante.beneficios!.trim().isNotEmpty) ...[
                        _buildSectionTitle('Beneficios'),
                        ...vacante.beneficios!.split('\n')
                            .where((ben) => ben.trim().isNotEmpty)
                            .map((ben) => _buildBulletPoint(ben.trim())),
                        const SizedBox(height: 24),
                      ],

                      // 3. CORRECCIÓN: Validamos mostrarSalario y usamos los nuevos campos
                      if (vacante.mostrarSalario && (vacante.salarioMin != null || vacante.salarioMax != null)) ...[
                        _buildSectionTitle('Salario Ofertado'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: accentLightGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentLightGreen),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.monetization_on_outlined, color: primaryDarkGreen),
                              const SizedBox(width: 8),
                              Text(
                                _formatearSalario(vacante.salarioMin, vacante.salarioMax),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDarkGreen),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)]),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: widget.onPostular,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryDarkGreen, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text('Postular a esta vacante', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18, color: Colors.black54)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, height: 1.4, fontSize: 15))),
        ],
      ),
    );
  }
}