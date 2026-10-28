import 'package:mobile_ssas_rrhh/features/equipo/model/contrato.dart';
import 'package:mobile_ssas_rrhh/shared/format/moneda.dart';
import 'package:mobile_ssas_rrhh/shared/referencias/referencias.dart';

/// El contrato vigente del colaborador y sus versiones anteriores
/// (T3-28 · HU-11 · CU-21).
///
/// No define claves del API: cada versión es una fila de la tabla
/// "contrato" leída con el modelo de T3-29, y el nombre del cargo sale de
/// GET /cargos, que ya existe en rrhh-api.
///
/// Los contratos son versionados: cada cambio (renovación, ascenso, aumento)
/// cierra el vigente y abre uno nuevo que apunta al anterior con
/// contrato_anterior_id y explica el porqué en motivo_cambio.
class HistorialContratos {
  /// El contrato en curso, o null si ya no tiene uno vigente.
  final Contrato? vigente;

  /// Las versiones cerradas, de la más reciente a la más antigua.
  final List<Contrato> anteriores;

  /// Los cargos por id, para mostrar su nombre.
  final Map<String, CargoRef> cargos;

  const HistorialContratos({
    required this.vigente,
    required this.anteriores,
    this.cargos = const {},
  });

  /// Separa el vigente de los demás y los ordena del más nuevo al más viejo.
  factory HistorialContratos.desde(
    Iterable<Contrato> contratos,
    Map<String, CargoRef> cargos,
  ) {
    final todos = contratos.toList()..sort(masRecientePrimero);
    final vigente = todos.where((c) => c.esVigente).firstOrNull;
    return HistorialContratos(
      vigente: vigente,
      anteriores: todos.where((c) => c != vigente).toList(),
      cargos: cargos,
    );
  }

  bool get estaVacio => vigente == null && anteriores.isEmpty;

  String? cargoDe(Contrato c) => cargos[c.cargoId]?.nombre;

  /// Por fecha de inicio, la más reciente primero. Sin fecha, al final.
  static int masRecientePrimero(Contrato a, Contrato b) {
    final fa = a.fechaInicio ?? a.fechaRegistro;
    final fb = b.fechaInicio ?? b.fechaRegistro;
    if (fa == null && fb == null) return a.id.compareTo(b.id);
    if (fa == null) return 1;
    if (fb == null) return -1;
    return fb.compareTo(fa);
  }

  // ------------------------------------------------------------- para mostrar

  /// "PLAZO_FIJO" -> "Plazo fijo", "TIEMPO_COMPLETO" -> "Tiempo completo".
  /// Los literales de los enums de T3-01 se leen como texto: si el backend
  /// agrega uno nuevo, se muestra igual en vez de romperse.
  static String legible(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return '—';
    final conTilde = _conTilde[v.toUpperCase()];
    if (conTilde != null) return conTilde;
    final texto = v.replaceAll('_', ' ').toLowerCase();
    return texto[0].toUpperCase() + texto.substring(1);
  }

  /// Los literales van sin tilde en la base de datos; en pantalla, no.
  static const _conTilde = {
    'HIBRIDO': 'Híbrido',
    'CONSULTORIA': 'Consultoría',
    'PASANTIA': 'Pasantía',
  };

  /// "Bs 9.800,00". Si el contrato está en otra moneda, la muestra por su
  /// código en vez de fingir que son bolivianos.
  static String salario(Contrato c) {
    final moneda = (c.moneda ?? '').trim().toUpperCase();
    if (moneda.isEmpty || moneda == 'BOB' || moneda == 'BS') {
      return Moneda.bs(c.salarioBasico);
    }
    return '$moneda ${Moneda.sinSimbolo(c.salarioBasico)}';
  }

  /// "01/04/2026" o "—".
  static String fecha(DateTime? f) {
    if (f == null) return '—';
    return '${f.day.toString().padLeft(2, '0')}/'
        '${f.month.toString().padLeft(2, '0')}/${f.year}';
  }

  /// La fecha de fin, o "Indefinido" si el contrato no tiene.
  static String hasta(Contrato c) =>
      c.fechaFin == null ? 'Indefinido' : fecha(c.fechaFin);

  /// "01/02/2025 al 31/03/2026".
  static String periodo(Contrato c) => '${fecha(c.fechaInicio)} al ${hasta(c)}';
}
