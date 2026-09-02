/// Datos del postulante que viajan en el multipart (T1-20).
///
/// ESTE ARCHIVO ES EL ÚNICO LUGAR donde vive el contrato del API.
/// Las CLAVES de [toFields] son exactamente las columnas de la tabla
/// "postulante" del diagrama de clases del equipo:
///   nombres, apellidos, ci, email, telefono, ciudad,
///   nivel_educativo, anios_experiencia, linkedin
/// No las traduzcas ni les cambies el plural. Si el backend usa otras,
/// se cambian aquí y toda la app se adapta sola.
class Postulante {
  // Obligatorios (*)
  final String nombres;
  final String apellidos;
  final String email;

  // Opcionales
  final String? ci;
  final String? telefono;
  final String? ciudad;
  final String? nivelEducativo; // -> nivel_educativo
  final int? aniosExperiencia; // -> anios_experiencia
  final String? linkedin;

  const Postulante({
    required this.nombres,
    required this.apellidos,
    required this.email,
    this.ci,
    this.telefono,
    this.ciudad,
    this.nivelEducativo,
    this.aniosExperiencia,
    this.linkedin,
  });

  /// Campos de texto del multipart. Los opcionales vacíos no se mandan:
  /// así el backend guarda NULL en vez de cadena vacía.
  Map<String, String> toFields() {
    final campos = <String, String>{
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      'email': email.trim(),
    };

    void agregar(String clave, String? valor) {
      final v = valor?.trim();
      if (v != null && v.isNotEmpty) campos[clave] = v;
    }

    agregar('ci', ci);
    agregar('telefono', telefono);
    agregar('ciudad', ciudad);
    agregar('nivel_educativo', nivelEducativo);
    agregar('anios_experiencia', aniosExperiencia?.toString());
    agregar('linkedin', linkedin);

    return campos;
  }
}
