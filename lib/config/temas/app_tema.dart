import 'package:flutter/material.dart';

class AppTema {
  // Paleta de colores inspirada en Travel Agency Template
  static const Color travelCyan = Color(0xFF00BCD4); // Turquesa vibrante principal
  static const Color travelCyanLight = Color(0xFF26C6DA); // Cyan claro para hover/activo
  static const Color travelNavy = Color(0xFF1A2332); // Azul oscuro para contraste
  static const Color travelDarkBg = Color(0xFF0D1B2A); // Fondo oscuro profundo
  static const Color travelWhite = Color(0xFFFAFAFA); // Blanco suave
  static const Color travelGold = Color(0xFFFFB300); // Dorado para acentos especiales
  static const Color travelGreen = Color(0xFF00C853); // Verde para éxito
  static const Color travelRed = Color(0xFFD32F2F); // Rojo para alertas

  static ThemeData get temaHaku {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Esquema de colores
      colorScheme: ColorScheme.light(
        primary: travelCyan,
        secondary: travelCyanLight,
        tertiary: travelGold,
        error: travelRed,
        surface: travelWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: travelNavy,
        onError: Colors.white,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: travelCyan,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Botón flotante (FAB)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: travelCyan,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: travelCyan,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          foregroundColor: travelCyan,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botones outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: travelCyan,
          side: const BorderSide(color: travelCyan, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Barra de navegación inferior
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: travelCyan,
        unselectedItemColor: Colors.grey[600],
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tarjetas
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: travelNavy.withValues(alpha: 0.1),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: travelCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: travelRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey[700]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),

      // Tipografía
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: travelNavy,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: travelNavy,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: travelNavy,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: travelNavy,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: travelNavy,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: travelNavy,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: travelNavy,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: travelNavy,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: travelNavy,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.grey[800],
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Iconos
      iconTheme: IconThemeData(
        color: travelNavy,
        size: 24,
      ),

      // Divisores
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 16,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: travelCyan.withValues(alpha: 0.1),
        selectedColor: travelCyan,
        labelStyle: const TextStyle(
          color: travelNavy,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Scaffold
      scaffoldBackgroundColor: travelWhite,
    );
  }

  // Tema oscuro (opcional)
  static ThemeData get temaHakuOscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.dark(
        primary: travelCyan,
        secondary: travelCyanLight,
        tertiary: travelGold,
        error: travelRed,
        surface: travelDarkBg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: travelNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      scaffoldBackgroundColor: travelDarkBg,
    );
  }
}
