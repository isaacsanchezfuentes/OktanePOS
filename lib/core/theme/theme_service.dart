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

  // Constantes de botones funcionales de alto contraste
  static const Color keyAC = Color(0xFF16A34A);        // Verde Esmeralda Casio
  static const Color keyDEL = Color(0xFFEA580C);       // Ámbar/Naranja Vivo Casio (Retroceso)
  static const Color keyC = Color(0xFFDC2626);         // Rojo Intenso (CLEAR 'C')
  static const Color accentCobrar = Color(0xFF2563EB); // Azul Eléctrico para botón COBRAR

  // Gradiente de Chasis de Aluminio Cepillado con reflejos de luz
  Gradient get currentChassisGradient {
    switch (currentTheme) {
      case AppThemeMode.casioBlue:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F326E), Color(0xFF1E5BB5), Color(0xFF13428E), Color(0xFF256CD6), Color(0xFF0D2B5E)],
          stops: [0.0, 0.25, 0.55, 0.75, 1.0],
        );
      case AppThemeMode.casioPink:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A1344), Color(0xFFB8286C), Color(0xFF9E1F5A), Color(0xFFC7367B), Color(0xFF6B103B)],
          stops: [0.0, 0.25, 0.55, 0.75, 1.0],
        );
      case AppThemeMode.slateIndustrial:
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F24), Color(0xFF2E3740), Color(0xFF232A31), Color(0xFF38434E), Color(0xFF161A1F)],
          stops: [0.0, 0.25, 0.55, 0.75, 1.0],
        );
    }
  }

  // Tokens dinámicos por tema
  Color get scaffoldBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF262E35);
      case AppThemeMode.casioBlue:
        return const Color(0xFF13428E);
      case AppThemeMode.casioPink:
        return const Color(0xFF9E1F5A);
    }
  }

  Color get cardSurface {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF1C2229);
      case AppThemeMode.casioBlue:
        return const Color(0xFF1B365D);
      case AppThemeMode.casioPink:
        return const Color(0xFF7A1444);
    }
  }

  Color get displayBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF1E252D);
      case AppThemeMode.casioBlue:
        return const Color(0xFFD9EBD9); // LCD clásico verdoso
      case AppThemeMode.casioPink:
        return const Color(0xFFD4E7D6); // LCD claro
    }
  }

  Color get displayText {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFFECEFF2);
      case AppThemeMode.casioBlue:
      case AppThemeMode.casioPink:
        return const Color(0xFF0F172A); // Tinta negra sólida LCD
    }
  }

  Color get padButtonBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF2A323D);
      case AppThemeMode.casioBlue:
      case AppThemeMode.casioPink:
        return const Color(0xFFFFFFFF); // Blanco puro para alto contraste
    }
  }

  Color get padButtonText {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFFFFFFFF);
      case AppThemeMode.casioBlue:
      case AppThemeMode.casioPink:
        return const Color(0xFF111827); // Negro grafito profundo
    }
  }

  Color get padBorder {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF161B22);
      case AppThemeMode.casioBlue:
      case AppThemeMode.casioPink:
        return const Color(0xFFCBD5E1);
    }
  }

  Color get accentAction => accentCobrar;

  /// Retorna la configuración global de ThemeData para toda la app
  ThemeData get currentThemeData {
    final isDark = currentTheme == AppThemeMode.slateIndustrial;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentCobrar,
        surface: cardSurface,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
