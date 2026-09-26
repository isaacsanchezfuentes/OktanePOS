import 'package:flutter/material.dart';

enum AppThemeMode { slateIndustrial, casioBlue, casioPink }

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  AppThemeMode currentTheme = AppThemeMode.slateIndustrial;

  void setTheme(AppThemeMode mode) {
    currentTheme = mode;
    notifyListeners();
  }

  // Constantes de botones funcionales
  static const Color accentCobrar = Color(0xFF2E90E5); // Azul vivo constante para el botón COBRAR
  static const Color keyAC = Color(0xFF22C55E);        // Verde Casio
  static const Color keyDEL = Color(0xFFF59E0B);       // Ámbar/Naranja Casio (Retroceso)
  static const Color keyC = Color(0xFFEF4444);         // Rojo suave (CLEAR 'C')

  // Tokens dinámicos por tema
  Color get scaffoldBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF0D1116);
      case AppThemeMode.casioBlue:
        return const Color(0xFF13428E);
      case AppThemeMode.casioPink:
        return const Color(0xFF9E1F5A);
    }
  }

  Color get cardSurface {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF1E252D);
      case AppThemeMode.casioBlue:
        return const Color(0xFF1B4E9B);
      case AppThemeMode.casioPink:
        return const Color(0xFFB82A6C);
    }
  }

  Color get displayBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF1E252D);
      case AppThemeMode.casioBlue:
        return const Color(0xFFCFE1D2); // LCD clásico verdoso
      case AppThemeMode.casioPink:
        return const Color(0xFFD6E8D8); // LCD claro
    }
  }

  Color get displayText {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFFECEFF2);
      case AppThemeMode.casioBlue:
        return const Color(0xFF101913); // Tinta LCD oscura
      case AppThemeMode.casioPink:
        return const Color(0xFF1A211B);
    }
  }

  Color get padButtonBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF1E252D);
      case AppThemeMode.casioBlue:
        return const Color(0xFFE8EEF5);
      case AppThemeMode.casioPink:
        return const Color(0xFFFBE4EE);
    }
  }

  Color get padButtonText {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFFECEFF2);
      case AppThemeMode.casioBlue:
        return const Color(0xFF102A54);
      case AppThemeMode.casioPink:
        return const Color(0xFF4A0A28);
    }
  }

  Color get accentAction => accentCobrar;
}
