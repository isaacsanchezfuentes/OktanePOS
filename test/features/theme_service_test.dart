import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/core/theme/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Casio Scientific POS Themes & ThemeData Tests', () {
    test('Default theme is Slate Industrial with currentThemeData and metallic gradient', () {
      final theme = ThemeService.instance;
      expect(theme.currentTheme, AppThemeMode.slateIndustrial);
      expect(theme.scaffoldBg, const Color(0xFF262E35));
      expect(theme.cardSurface, const Color(0xFF1C2229));
      expect(theme.displayBg, const Color(0xFF1E252D));
      expect(theme.displayText, const Color(0xFFECEFF2));

      final themeData = theme.currentThemeData;
      expect(themeData.scaffoldBackgroundColor, const Color(0xFF262E35));
      expect(themeData.cardColor, const Color(0xFF1C2229));

      expect(ThemeService.accentCobrar, const Color(0xFF2563EB));
      expect(ThemeService.keyAC, const Color(0xFF16A34A));
      expect(ThemeService.keyDEL, const Color(0xFFEA580C));
      expect(ThemeService.keyC, const Color(0xFFDC2626));
      expect(theme.currentChassisGradient, isA<LinearGradient>());
    });

    test('Casio Blue theme provides green LCD display and white pad button background', () {
      final theme = ThemeService.instance;
      theme.setTheme(AppThemeMode.casioBlue);

      expect(theme.currentTheme, AppThemeMode.casioBlue);
      expect(theme.scaffoldBg, const Color(0xFF13428E));
      expect(theme.cardSurface, const Color(0xFF1B365D));
      expect(theme.displayBg, const Color(0xFFD9EBD9));
      expect(theme.displayText, const Color(0xFF0F172A));
      expect(theme.padButtonBg, const Color(0xFFFFFFFF));
      expect(theme.padButtonText, const Color(0xFF111827));

      final themeData = theme.currentThemeData;
      expect(themeData.scaffoldBackgroundColor, const Color(0xFF13428E));
    });

    test('Casio Pink theme provides light LCD display and white pad button background', () {
      final theme = ThemeService.instance;
      theme.setTheme(AppThemeMode.casioPink);

      expect(theme.currentTheme, AppThemeMode.casioPink);
      expect(theme.scaffoldBg, const Color(0xFF9E1F5A));
      expect(theme.cardSurface, const Color(0xFF7A1444));
      expect(theme.displayBg, const Color(0xFFD4E7D6));
      expect(theme.padButtonBg, const Color(0xFFFFFFFF));

      // Reset to Slate Industrial
      theme.setTheme(AppThemeMode.slateIndustrial);
      expect(theme.currentTheme, AppThemeMode.slateIndustrial);
    });
  });
}
