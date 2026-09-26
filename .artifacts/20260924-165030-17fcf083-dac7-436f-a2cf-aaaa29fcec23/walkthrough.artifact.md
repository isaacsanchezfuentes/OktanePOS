# Walkthrough - POS Quick Charge, Quick Language Toggle (ES/EN)

Se implementó el **Toggle de Idioma en Vivo (`🇲🇽 ES` / `🇺🇸 EN`) en la Pantalla de Cobro Rápido (`QuickChargeScreen`)**.

---

## Componentes Entregados

### 1. Servicio de Localización (`AppLocale`)
- [app_locale.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/core/localization/app_locale.dart):
  - Creado `AppLocale` como un `ChangeNotifier` Singleton (`AppLocale.instance`).
  - Implementado el método `toggle()` que alterna la variable `currentLang` entre `'es'` y `'en'`, notificando a la interfaz.
  - Diccionario de traducciones clave y función helper global `tr(key)`.

### 2. Botón Toggle y Traducción Reactiva en `QuickChargeScreen`
- [quick_charge_screen.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/features/charge/screens/quick_charge_screen.dart):
  - Añadido el botón estilizado `'🇲🇽 ES'` / `'🇺🇸 EN'` en la barra superior (AppBar acciones).
  - Envuelto el cuerpo principal en `ListenableBuilder(listenable: AppLocale.instance, builder: (context, _) => ...)` para que al alternar el idioma, todos los rótulos y botones de la calculadora cambien en tiempo real sin reiniciar la aplicación.
- [amount_display.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/features/charge/widgets/amount_display.dart):
  - Envuelto en `ListenableBuilder` traduciendo el encabezado "Monto a cobrar" / "Amount to charge".

---

## Verification Summary

### Pruebas Unitarias (`flutter test`)
- Comando: `flutter test test/widget_test.dart test/features/charge_test.dart test/features/printer_test.dart test/features/cash_cut_test.dart test/features/shift_test.dart test/features/shift_policy_test.dart test/features/tables_rbac_test.dart test/features/table_charging_test.dart test/features/menu_catalog_test.dart test/features/pre_add_dialog_test.dart test/features/table_order_test.dart test/features/printer_precheck_test.dart test/features/atomic_ticket_test.dart test/features/order_consolidation_test.dart test/features/relational_persistence_test.dart test/features/uuid_validation_test.dart test/features/waiter_sanitization_test.dart test/features/zone_uuid_test.dart test/features/table_parsing_test.dart test/features/round_math_test.dart test/features/item_cancellation_test.dart test/features/singleton_table_service_test.dart test/features/calculator_table_bridge_test.dart test/features/language_toggle_test.dart`
- Resultado: **`00:24 +43: All tests passed!`** (100% de 43 pruebas aprobadas).
