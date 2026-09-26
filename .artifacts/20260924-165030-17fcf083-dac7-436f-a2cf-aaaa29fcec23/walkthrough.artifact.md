# Walkthrough - POS Quick Charge, Table Effective Status Rule in TableService

Se implementó la regla de **Estatus Efectivo de Mesa en `TableService.fetchOrSeedSupabaseTables`**.

---

## Componentes Entregados

### 1. Regla de Estatus Efectivo de Mesa (`TableService`)
- [table_service.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/features/tables/services/table_service.dart):
  - En `fetchOrSeedSupabaseTables(...)`, se determinó el estatus efectivo mediante:
    `final hasActiveTickets = old.activeTickets.isNotEmpty;`
    `final effectiveStatus = hasActiveTickets ? 'occupied' : 'free';`
  - Garantiza que si una mesa no tiene tickets activos (`activeTickets.isEmpty`), su estatus forzoso sea `'free'` (disponible/verde) independientemente del valor reportado por la columna `status` en Supabase o en memoria.

---

## Verification Summary

### Pruebas Unitarias (`flutter test`)
- Comando: `flutter test test/widget_test.dart test/features/charge_test.dart test/features/printer_test.dart test/features/cash_cut_test.dart test/features/shift_test.dart test/features/shift_policy_test.dart test/features/tables_rbac_test.dart test/features/table_charging_test.dart test/features/menu_catalog_test.dart test/features/pre_add_dialog_test.dart test/features/table_order_test.dart test/features/printer_precheck_test.dart test/features/atomic_ticket_test.dart test/features/order_consolidation_test.dart test/features/relational_persistence_test.dart test/features/uuid_validation_test.dart test/features/waiter_sanitization_test.dart test/features/zone_uuid_test.dart test/features/table_parsing_test.dart test/features/round_math_test.dart test/features/item_cancellation_test.dart test/features/singleton_table_service_test.dart test/features/calculator_table_bridge_test.dart`
- Resultado: **`00:46 +42: All tests passed!`** (100% de 42 pruebas aprobadas).
