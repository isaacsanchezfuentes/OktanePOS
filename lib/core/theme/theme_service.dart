import 'package:flutter/material.dart';

enum AppThemeMode {
  slateIndustrial,
  classicBlue,
  classicPink;

  static const AppThemeMode casioBlue = classicBlue;
  static const AppThemeMode casioPink = classicPink;
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  AppThemeMode currentTheme = AppThemeMode.slateIndustrial;

  void setTheme(AppThemeMode mode) {
    currentTheme = mode;
    notifyListeners();
  }

  // Constantes de botones funcionales de alto contraste
  static const Color keyAC = Color(0xFF16A34A);        // Verde Esmeralda
  static const Color keyDEL = Color(0xFFEA580C);       // Ámbar/Naranja Vivo (Retroceso)
  static const Color keyC = Color(0xFFDC2626);         // Rojo Intenso (CLEAR 'C')
  static const Color accentCobrar = Color(0xFF2563EB); // Azul Eléctrico para botón COBRAR

  // Gradiente de Chasis de Aluminio Cepillado con reflejos de luz y brillo especular
  Gradient get currentChassisGradient {
    switch (currentTheme) {
      case AppThemeMode.classicBlue:
        return const LinearGradient(
          begin: Alignment(-0.8, -1.0),
          end: Alignment(0.8, 1.0),
          colors: [
            Color(0xFF0D2D63),
            Color(0xFF1E5BB5), // Franja de brillo aluminio
            Color(0xFF123B82),
            Color(0xFF286ED4), // Reflejo especular
            Color(0xFF092047),
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        );
      case AppThemeMode.classicPink:
        return const LinearGradient(
          begin: Alignment(-0.8, -1.0),
          end: Alignment(0.8, 1.0),
          colors: [
            Color(0xFF700F3B),
            Color(0xFFB52668), // Franja de brillo aluminio
            Color(0xFF8B164C),
            Color(0xFFC7367B), // Reflejo especular
            Color(0xFF5E0B31),
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        );
      case AppThemeMode.slateIndustrial:
      default:
        return const LinearGradient(
          begin: Alignment(-0.8, -1.0),
          end: Alignment(0.8, 1.0),
          colors: [
            Color(0xFF1E242B),
            Color(0xFF38434F), // Reflejo de luz metálica
            Color(0xFF222931),
            Color(0xFF43505E), // Brillo especular
            Color(0xFF161A1F),
          ],
          stops: [0.0, 0.28, 0.52, 0.78, 1.0],
        );
    }
  }

  // Tokens dinámicos por tema
  Color get scaffoldBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF262E35);
      case AppThemeMode.classicBlue:
        return const Color(0xFF13428E);
      case AppThemeMode.classicPink:
        return const Color(0xFF9E1F5A);
    }
  }

  Color get cardSurface {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFF1C2229);
      case AppThemeMode.classicBlue:
        return const Color(0xFF1B365D);
      case AppThemeMode.classicPink:
        return const Color(0xFF7A1444);
    }
  }

  /// Display LCD claro universal verde retro (#D9EBD9) en todos los temas
  Color get displayBg => const Color(0xFFD9EBD9);

  /// Tinta negra sólida (#0F172A) en todos los temas para máxima legibilidad LCD
  Color get displayText => const Color(0xFF0F172A);

  Color get padButtonBg => const Color(0xFFFFFFFF); // Blanco puro en todos los temas

  Color get padButtonText => const Color(0xFF111827); // Negro grafito profundo en todos los temas

  Color get padBorder => const Color(0xFFCBD5E1);

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
