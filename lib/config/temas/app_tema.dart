import 'package:flutter/material.dart';

class AppTema {
  static ThemeData get temaAzulAventura {
    const azulPrimario = Color(0xFF1565C0); // Azul intenso Cusco
    const azulSecundario = Color(0xFF1E88E5);
    const fondoClaro = Color(0xFFF5F7FA);

    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: azulPrimario,
        secondary: azulSecundario,
        surface: Colors.white,
        background: fondoClaro,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: fondoClaro,
      appBarTheme: const AppBarTheme(
        backgroundColor: azulPrimario,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: azulPrimario,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: azulPrimario,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(
          color: azulPrimario,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
