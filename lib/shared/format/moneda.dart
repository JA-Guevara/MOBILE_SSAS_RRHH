/// Formateo de importes en bolivianos.
///
/// Se escribe a mano en vez de usar el paquete intl porque el proyecto no lo
/// tiene y para una sola moneda no compensa la dependencia. Bolivia escribe
/// el millar con punto y el decimal con coma:  Bs 12.345,67
///
/// Ubicación:  lib/shared/format/moneda.dart
abstract final class Moneda {
  /// Lo que se muestra cuando el backend no mandó importe. No se pone
  /// "Bs 0,00" porque cero y "no hay dato" no son lo mismo en una boleta.
  static const sinDato = '—';

  /// 12345.6 -> "Bs 12.345,60".  null -> "—".
  static String bs(num? valor) {
    if (valor == null) return sinDato;

    final negativo = valor < 0;
    // toStringAsFixed redondea a 2 decimales, que es lo que exige una boleta.
    final texto = valor.abs().toStringAsFixed(2);

    final punto = texto.indexOf('.');
    final entero = _conMillares(texto.substring(0, punto));
    final decimales = texto.substring(punto + 1);

    return '${negativo ? '-' : ''}Bs $entero,$decimales';
  }

  /// Igual que [bs] pero sin el símbolo, para columnas donde ya se sabe que
  /// todo va en bolivianos.
  static String sinSimbolo(num? valor) {
    if (valor == null) return sinDato;
    return bs(valor).replaceFirst('Bs ', '');
  }

  /// 8.5 -> "8,5%".  8.0 -> "8%".  null -> "".
  static String porcentaje(num? valor) {
    if (valor == null) return '';
    final texto = valor == valor.roundToDouble()
        ? valor.round().toString()
        : valor.toString().replaceFirst('.', ',');
    return '$texto%';
  }

  /// "12345" -> "12.345"
  static String _conMillares(String entero) {
    final buffer = StringBuffer();
    for (var i = 0; i < entero.length; i++) {
      // Un punto cada tres dígitos contando desde la derecha.
      if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
      buffer.write(entero[i]);
    }
    return buffer.toString();
  }
}
