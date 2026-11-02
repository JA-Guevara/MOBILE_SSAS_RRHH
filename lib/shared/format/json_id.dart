/// Lee un id del JSON del backend como texto.
///
/// En rrhh-api TODOS los ids son UUID ("3f2a…"), no números. Leerlos con
/// `as num?` revienta con el JSON real (fue el hallazgo H-1 del ranking en
/// T2-21). Aquí se aceptan las dos formas: el UUID del backend y el número
/// de los servicios falsos, que llega convertido a "7".
String? leerId(Object? valor) {
  if (valor == null) return null;
  final s = valor.toString().trim();
  return s.isEmpty ? null : s;
}
