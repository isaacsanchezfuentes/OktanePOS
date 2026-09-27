import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/core/theme/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Metallic Chassis & Clear LCD Theme Service Tests', () {
    test('Default theme is Slate Industrial with metallic specular gradient and clear LCD', () {
      final theme = ThemeService.instance;
      expect(theme.currentTheme, AppThemeMode.slateIndustrial);
      expect(theme.scaffoldBg, const Color(0xFFE2E4E7));
      expect(theme.cardSurface, const Color(0xFFD4D8DD));
      expect(theme.displayBg, const Color(0xFFC4D8C2));
      expect(theme.displayText, const Color(0xFF0F172A));

      final themeData = theme.currentThemeData;
      expect(themeData.scaffoldBackgroundColor, const Color(0xFFE2E4E7));
      expect(themeData.cardColor, const Color(0xFFD4D8DD));

      expect(ThemeService.accentCobrar, const Color(0xFF2563EB));
      expect(ThemeService.keyAC, const Color(0xFF16A34A));
      expect(ThemeService.keyDEL, const Color(0xFFE5B324));
      expect(ThemeService.keyC, const Color(0xFFC02626));
      expect(theme.currentChassisGradient, isA<LinearGradient>());
    });

    test('Classic Blue theme provides specular metallic gradient and clear LCD display', () {
      final theme = ThemeService.instance;
      theme.setTheme(AppThemeMode.classicBlue);

      expect(theme.currentTheme, AppThemeMode.classicBlue);
      expect(theme.scaffoldBg, const Color(0xFF13428E));
      expect(theme.cardSurface, const Color(0xFF1B365D));
      expect(theme.displayBg, const Color(0xFFC4D8C2));
      expect(theme.displayText, const Color(0xFF0F172A));
      expect(theme.padButtonBg, const Color(0xFFF8F9FA));
      expect(theme.padButtonText, const Color(0xFF111827));

      final themeData = theme.currentThemeData;
      expect(themeData.scaffoldBackgroundColor, const Color(0xFF13428E));
    });

    test('Classic Pink theme provides specular metallic gradient and clear LCD display', () {
      final theme = ThemeService.instance;
      theme.setTheme(AppThemeMode.classicPink);

      expect(theme.currentTheme, AppThemeMode.classicPink);
      expect(theme.scaffoldBg, const Color(0xFF9E1F5A));
      expect(theme.cardSurface, const Color(0xFF7A1444));
      expect(theme.displayBg, const Color(0xFFC4D8C2));
      expect(theme.padButtonBg, const Color(0xFFF8F9FA));

      // Reset to Slate Industrial
      theme.setTheme(AppThemeMode.slateIndustrial);
      expect(theme.currentTheme, AppThemeMode.slateIndustrial);
    });
  });
}
