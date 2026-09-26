import 'package:flutter/material.dart';

class TableTheme {
  // Fondos y Capas (bg-950 a bg-700)
  static const Color bg950 = Color(0xFF0D1116); // Fondo raíz de la app
  static const Color bg900 = Color(0xFF151A21); // Contenido principal
  static const Color bg800 = Color(0xFF1E252D); // Tarjetas, paneles, tickets
  static const Color bg700 = Color(0xFF2A333D); // Elevado / hover
  static const Color border = Color(0xFF3A454F); // Divisores sutiles
  static const Color borderStrong = Color(0xFF4C5964); // Bordes de foco/hover

  // Tipografía
  static const Color textPrimary = Color(0xFFECEFF2);   // Texto principal, montos
  static const Color textSecondary = Color(0xFF9AA5AF); // Etiquetas, texto de apoyo
  static const Color textMuted = Color(0xFF667079);     // Placeholders, metadatos

  // Acento (Azul Industrial)
  static const Color accent = Color(0xFF2E90E5);      // Acción principal: cobrar, confirmar
  static const Color accentHover = Color(0xFF1D6FBD); // Estado presionado / hover

  // Semánticos
  static const Color success = Color(0xFF3FB27F); // Pagado, orden completada
  static const Color warning = Color(0xFFE0A73B); // En espera, borrador (industrial)
  static const Color danger = Color(0xFFE5484D);  // Anulado, error de cobro

  // Mapeo semántico para mesas y canvas
  static const Color floorBackground = bg950;
  static const Color zoneBarBackground = bg900;
  static const Color cardSurface = bg800;

  // Estados de mesa
  static const Color freeBg = Color(0xFF10261E);
  static const Color freeBorder = success;
  static const Color freeText = success;

  static const Color occupiedBg = Color(0xFF292215);
  static const Color occupiedBorder = warning;
  static const Color occupiedText = warning;

  static const Color billedBg = Color(0xFF14243B);
  static const Color billedBorder = accent;
  static const Color billedText = accent;
}
