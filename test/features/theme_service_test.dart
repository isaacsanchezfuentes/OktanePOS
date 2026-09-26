import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/core/theme/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Casio Scientific POS Themes & Keypad Tokens Tests', () {
    test('Default theme is Slate Industrial with functional key constants', () {
      final theme = ThemeService.instance;
      expect(theme.currentTheme, AppThemeMode.slateIndustrial);
      expect(theme.scaffoldBg, const Color(0xFF0D1116));
      expect(theme.displayBg, const Color(0xFF1E252D));
      expect(theme.displayText, const Color(0xFFECEFF2));

      expect(ThemeService.accentCobrar, const Color(0xFF2E90E5));
      expect(ThemeService.keyAC, const Color(0xFF22C55E));
      expect(ThemeService.keyDEL, const Color(0xFFF59E0B));
      expect(ThemeService.keyC, const Color(0xFFEF4444));
    });

    test('Casio Blue theme provides green LCD background and dark LCD ink', () {
      final theme = ThemeService.instance;
      theme.setTheme(AppThemeMode.casioBlue);

      expect(theme.currentTheme, AppThemeMode.casioBlue);
      expect(theme.scaffoldBg, const Color(0xFF13428E));
      expect(theme.displayBg, const Color(0xFFCFE1D2));
      expect(theme.displayText, const Color(0xFF101913));
      expect(theme.padButtonBg, const Color(0xFFE8EEF5));
      expect(theme.padButtonText, const Color(0xFF102A54));
    });

    test('Casio Pink theme provides light LCD background and deep pink scaffold', () {
      final theme = ThemeService.instance;
      theme.setTheme(AppThemeMode.casioPink);

      expect(theme.currentTheme, AppThemeMode.casioPink);
      expect(theme.scaffoldBg, const Color(0xFF9E1F5A));
      expect(theme.displayBg, const Color(0xFFD6E8D8));
      expect(theme.displayText, const Color(0xFF1A211B));
      expect(theme.padButtonBg, const Color(0xFFFBE4EE));
      expect(theme.padButtonText, const Color(0xFF4A0A28));

      // Reset to Slate Industrial
      theme.setTheme(AppThemeMode.slateIndustrial);
      expect(theme.currentTheme, AppThemeMode.slateIndustrial);
    });
  });
}
