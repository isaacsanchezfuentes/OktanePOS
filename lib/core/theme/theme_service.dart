import 'package:flutter/material.dart';

enum AppThemeMode {
  slateIndustrial,
  classicBlue,
  classicPink;

  static const AppThemeMode casioBlue = classicBlue;
  static const AppThemeMode casioPink = classicPink;
  static const AppThemeMode roseGold = classicPink; // Alias directo para Oro Rosa
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  AppThemeMode currentTheme = AppThemeMode.slateIndustrial;

  void setTheme(AppThemeMode mode) {
    if (currentTheme != mode) {
      currentTheme = mode;
      notifyListeners();
    }
  }

  /// Retorna la ruta del archivo de imagen de fondo según el tema activo
  String get currentFaceplateAsset {
    switch (currentTheme) {
      case AppThemeMode.classicPink:
        return 'assets/images/faceplates/rose_gold_faceplate.jpg';
      case AppThemeMode.classicBlue:
      case AppThemeMode.slateIndustrial:
      default:
        return 'assets/images/faceplates/Gemini_Generated_Image_cpngq2cpngq2cpng.jpg';
    }
  }

  /// Helper booleano para identificar si el modo Oro Rosa está activo
  bool get isRoseGold => currentTheme == AppThemeMode.classicPink;

  // Constantes de botones funcionales de alto contraste
  static const Color keyAC = Color(0xFF16A34A);        // Verde Esmeralda
  static const Color keyDEL = Color(0xFFE5B324);       // Amarillo Mostaza Suave (Retroceso ⌫)
  static const Color keyC = Color(0xFFC02626);         // Rojo Carmesí Vivo (CLEAR 'C')
  static const Color accentCobrar = Color(0xFF2563EB); // Azul Eléctrico para botón COBRAR

  // Gradiente de Chasis de Aluminio Cepillado Plateado brillante con brillo especular
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
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE2E4E7),
            Color(0xFFF7F8FA),
            Color(0xFFBEC2C8),
            Color(0xFFEFEFF2),
            Color(0xFFB5BAC1),
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        );
    }
  }

  // Tokens dinámicos por tema
  Color get scaffoldBg {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFFE2E4E7);
      case AppThemeMode.classicBlue:
        return const Color(0xFF13428E);
      case AppThemeMode.classicPink:
        return const Color(0xFF9E1F5A);
    }
  }

  Color get cardSurface {
    switch (currentTheme) {
      case AppThemeMode.slateIndustrial:
        return const Color(0xFFD4D8DD);
      case AppThemeMode.classicBlue:
        return const Color(0xFF1B365D);
      case AppThemeMode.classicPink:
        return const Color(0xFF7A1444);
    }
  }

  /// Display LCD verde vintage claro (#C4D8C2 a #B2CAB0) en todos los temas
  Color get displayBg => const Color(0xFFC4D8C2);

  /// Tinta negra/grafito sólida LCD (#0F172A / #152013) en todos los temas
  Color get displayText => const Color(0xFF0F172A);

  Color get padButtonBg => const Color(0xFFF8F9FA); // Blanco hueso / marfil de alta pureza

  Color get padButtonText => const Color(0xFF111827); // Negro grafito profundo

  Color get padBorder => const Color(0xFFCBD5E1);

  Color get accentAction => accentCobrar;

  /// Retorna la configuración global de ThemeData para toda la app
  ThemeData get currentThemeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardSurface,
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        hintStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2.0),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(color: Color(0xFF1E293B)),
        bodyMedium: TextStyle(color: Color(0xFF1E293B)),
        bodySmall: TextStyle(color: Color(0xFF334155)),
        labelSmall: TextStyle(color: Color(0xFF334155)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: const Color(0xFFFFFFFF),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1E293B),
          side: const BorderSide(color: Color(0xFF475569), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentCobrar,
        surface: const Color(0xFFFFFFFF),
        brightness: Brightness.light,
      ),
    );
  }
}