import 'package:flutter/material.dart';

class AppLocale extends ChangeNotifier {
  static final AppLocale instance = AppLocale._internal();
  AppLocale._internal();

  String currentLang = 'es'; // 'es' o 'en'

  void toggle() {
    currentLang = currentLang == 'es' ? 'en' : 'es';
    notifyListeners();
  }

  static final Map<String, Map<String, String>> _strings = {
    'es': {
      'amount_to_charge': 'Monto a cobrar',
      'table_location': 'Mesa / Ubicación',
      'waiter_service': 'Mesero / Atención',
      'view_table': 'TOMAR PEDIDO COMPLETO / VER MESA',
      'search_menu': 'Buscar producto en menú (ej. Tacos, ...)',
      'send_kitchen': 'MANDAR COCINA',
      'charge': 'COBRAR',
    },
    'en': {
      'amount_to_charge': 'Amount to charge',
      'table_location': 'Table / Location',
      'waiter_service': 'Waiter / Server',
      'view_table': 'FULL ORDER / VIEW TABLE',
      'search_menu': 'Search menu (e.g. Tacos, ...)',
      'send_kitchen': 'SEND TO KITCHEN',
      'charge': 'CHARGE',
    },
  };

  String tr(String key) => _strings[currentLang]?[key] ?? key;
}

/// Helper global shortcut
String tr(String key) => AppLocale.instance.tr(key);
