// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Paleta personalizada del usuario
  static const Color peachy = Color(0xFFFEDDD2); // #FEDDD2 - Melocotón suave
  static const Color vibrantRed = Color(
    0xFFFF4B34,
  ); // #FF4B34 - Rojo-naranja vibrante
  static const Color golden = Color(0xFFFAB782); // #FAB782 - Dorado cálido

  // Variaciones de los colores principales
  static const Color darkRed = Color(
    0xFFE63946,
  ); // Versión más oscura del rojo vibrante
  static const Color lightRed = Color(
    0xFFFF6B54,
  ); // Versión más clara del rojo vibrante
  static const Color darkGolden = Color(
    0xFFE5A066,
  ); // Versión más oscura del dorado
  static const Color lightGolden = Color(
    0xFFFDC99B,
  ); // Versión más clara del dorado

  // Colores de superficie y fondo
  static const Color surface = Color(0xFFFFFFFF); // Blanco puro
  static const Color surfaceLight = Color(
    0xFFFEF7F4,
  ); // Muy claro con tinte cálido
  static const Color surfaceWarm = Color(0xFFFDF5F2); // Superficie con calidez
  static const Color border = Color(0xFFE8D5C4); // Borde suave y cálido

  // Colores de texto
  static const Color textPrimary = Color(
    0xFF2D1B12,
  ); // Marrón oscuro para texto principal
  static const Color textSecondary = Color(
    0xFF5D4E40,
  ); // Marrón medio para texto secundario
  static const Color textTertiary = Color(
    0xFF8B7355,
  ); // Marrón claro para texto terciario
  static const Color textLight = Color(
    0xFFA69B8A,
  ); // Marrón muy claro para texto de apoyo

  // Colores de estado manteniendo la calidez
  static const Color success = Color(0xFF38A169); // Verde cálido para éxito
  static const Color warning = Color(
    0xFFD69E2E,
  ); // Amarillo dorado para advertencias
  static const Color error = Color(0xFFE53E3E); // Rojo cálido para errores
  static const Color info = Color(0xFF3182CE); // Azul cálido para información

  // Colores especiales para la app de física
  static const Color physicsAccent = Color(
    0xFFA0AEC0,
  ); // Gris azulado para física
  static const Color aiAccent = Color(0xFF4FD1C7); // Verde azulado para IA
  static const Color progressGreen = Color(
    0xFF48BB78,
  ); // Verde cálido para progreso

  // Colores para tema oscuro
  static const Color darkSurface = Color(
    0xFF1A0F0A,
  ); // Fondo oscuro con tinte cálido
  static const Color darkSurfaceLight = Color(
    0xFF2D1B12,
  ); // Superficie oscura cálida
  static const Color darkTextPrimary = Color(0xFFFEF7F4); // Texto claro cálido
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter', // Puedes cambiar por 'Roboto' si no tienes Inter
      // Esquema de colores con la paleta personalizada
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.vibrantRed,
        onPrimary: AppColors.surface,
        primaryContainer: AppColors.lightRed,
        onPrimaryContainer: AppColors.surface,
        secondary: AppColors.golden,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.lightGolden,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.peachy,
        onTertiary: AppColors.textPrimary,
        tertiaryContainer: AppColors.peachy,
        onTertiaryContainer: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.surface,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: AppColors.darkRed,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.peachy,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.textLight,
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.surface,
        inversePrimary: AppColors.lightRed,
        scrim: AppColors.textPrimary,
      ),

      // AppBar con el rojo vibrante
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.vibrantRed,
        foregroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.surface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.surface, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.surface, size: 24),
      ),

      // Botones elevados (principales) en rojo vibrante
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vibrantRed,
          foregroundColor: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.vibrantRed.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.vibrantRed,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Botones outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.vibrantRed,
          side: const BorderSide(color: AppColors.vibrantRed, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // FilledButton (dorado como secundario)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.golden,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Cards con el tinte melocotón
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.vibrantRed.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Campos de entrada con tonos cálidos
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.peachy,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vibrantRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.vibrantRed,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button en dorado
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.golden,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Progress Indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.vibrantRed,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),

      // Chips modernos con tonos cálidos
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.peachy,
        deleteIconColor: AppColors.textSecondary,
        disabledColor: AppColors.textLight,
        selectedColor: AppColors.vibrantRed,
        secondarySelectedColor: AppColors.golden,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.surface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.border),
      ),

      // Lista de tiles
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        iconColor: AppColors.vibrantRed,
        tileColor: AppColors.surface,
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 16,
      ),

      // Fondo del Scaffold con tinte cálido
      scaffoldBackgroundColor: AppColors.surfaceLight,

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

      // Text Theme con colores cálidos
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.6,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.4,
        ),
      ),

      // Configuraciones adicionales con tonos cálidos
      splashColor: AppColors.vibrantRed.withOpacity(0.1),
      highlightColor: AppColors.golden.withOpacity(0.1),
      focusColor: AppColors.vibrantRed.withOpacity(0.1),
      hoverColor: AppColors.golden.withOpacity(0.05),
    );
  }

  // Tema oscuro con tonos cálidos
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.lightRed,
        onPrimary: AppColors.textPrimary,
        primaryContainer: AppColors.vibrantRed,
        onPrimaryContainer: AppColors.surface,
        secondary: AppColors.golden,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.darkGolden,
        onSecondaryContainer: AppColors.lightGolden,
        tertiary: AppColors.peachy,
        onTertiary: AppColors.textPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceLight,
        onSurfaceVariant: AppColors.textLight,
        outline: Color(0xFF5D4E40),
        error: AppColors.error,
        onError: AppColors.surface,
      ),

      scaffoldBackgroundColor: AppColors.darkSurface,

      // AppBar para tema oscuro
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurfaceLight,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      ),

      // Cards para tema oscuro
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceLight,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF5D4E40), width: 0.5),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Campos de entrada para tema oscuro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5D4E40)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5D4E40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightRed, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8B7355),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Bottom Navigation para tema oscuro
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceLight,
        selectedItemColor: AppColors.lightRed,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Texto para tema oscuro
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          color: AppColors.textLight,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.6,
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textLight, size: 24),
    );
  }
}
