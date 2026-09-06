import 'package:flutter/material.dart';
import '../data/postulaciones_service_falso.dart';

class MiPostulacionScreen extends StatefulWidget {
  const MiPostulacionScreen({super.key});

  @override
  State<MiPostulacionScreen> createState() => _MiPostulacionScreenState();
}

class _MiPostulacionScreenState extends State<MiPostulacionScreen> {
  final _codigoController = TextEditingController();
  final _servicio = PostulacionesServiceFalso();
  
  bool _isLoading = false;
  PostulacionEstado? _resultado;
  String? _error;

  final Color primaryDarkGreen = const Color(0xFF0D4A22);

  void _buscarPostulacion() async {
    if (_codigoController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _resultado = null;
    });

    try {
      final data = await _servicio.consultarEstado(_codigoController.text);
      setState(() => _resultado = data);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryDarkGreen,
        title: const Text('Rastrear Postulación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Consulta el estado de tu proceso',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el código que recibiste al postularte.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            
            // Buscador
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoController,
                    decoration: InputDecoration(
                      hintText: 'Ej: DEV-123',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryDarkGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _buscarPostulacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDarkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Resultados
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade900))),
                  ],
                ),
              ),
              
            if (_resultado != null)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${_resultado!.codigo}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_resultado!.vacanteTitulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const Divider(height: 32),
                      _buildInfoRow('Etapa actual:', _resultado!.etapaActual),
                      const SizedBox(height: 12),
                      _buildInfoRow('Estado:', _resultado!.estado, isStatus: true),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    Color valueColor = Colors.black87;
    if (isStatus) {
      valueColor = value.toLowerCase() == 'rechazado' ? Colors.red.shade700 : primaryDarkGreen;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}