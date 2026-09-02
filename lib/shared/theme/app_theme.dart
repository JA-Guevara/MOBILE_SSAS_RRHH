import 'package:flutter/material.dart';

/// Tokens de diseño del proyecto SSAH, traducidos de la guía de interfaz.
/// Regla del equipo: "si un color no está aquí, no existe". No inventar valores.
///
/// Ubicación sugerida en tu repo:  lib/shared/theme/app_theme.dart
class AppColors {
  static const verde950 = Color(0xFF16382B); // barra/cabecera
  static const verde600 = Color(0xFF17845A); // primario, enlaces
  static const verde300 = Color(0xFFC4D4C6); // hito futuro (línea de tiempo)
  static const verde100 = Color(0xFFDEF2E4); // chip éxito
  static const mentaBg = Color(0xFFEEF4EC); // fondo de la app
  static const crema = Color(0xFFFBF6EA); // franjas y notas
  static const carta = Color(0xFFFFFFFF); // tarjetas
  static const borde = Color(0xFFE1E9E0);
  static const tinta = Color(0xFF22332B); // texto principal
  static const tinta2 = Color(0xFF66766D); // texto secundario
  static const ambar100 = Color(0xFFFBEED8); // inactivo / pendiente
  static const ambar700 = Color(0xFFA9731F);
  static const azul100 = Color(0xFFE7F0FA); // informativo
  static const azul700 = Color(0xFF3A6EA5);
  static const lila100 = Color(0xFFEFE8F7); // insignias de IA
  static const lila700 = Color(0xFF7A5AA6);
  static const rojo100 = Color(0xFFFBE4E1); // error (fondo)
  static const rojo700 = Color(0xFFB0483C); // error (texto)
}

/// Radios y sombras fijos de la guía.
class AppRadii {
  static const tarjeta = 14.0; // radio de tarjetas
  static const boton = 11.0; // radio de botones
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.mentaBg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.verde600,
        surface: AppColors.carta,
        error: AppColors.rojo700,
      ),
      // Títulos en serif (la guía pide Playfair Display; 'serif' es un
      // buen sustituto sin dependencias. Para el Playfair exacto, agrega
      // el paquete google_fonts y usa GoogleFonts.playfairDisplay).
      textTheme: base.textTheme.copyWith(
        displaySmall: const TextStyle(
          fontFamily: 'serif',
          fontSize: 26,
          color: AppColors.tinta,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.tinta,
        ),
        bodyMedium: const TextStyle(color: AppColors.tinta),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.boton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );
  }
}
