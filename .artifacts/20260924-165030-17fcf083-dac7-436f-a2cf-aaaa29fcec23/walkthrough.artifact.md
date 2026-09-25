# Walkthrough - POS Quick Charge, Individual Dispatched Items Breakdown & Item Cancellation

Se implementó el **Desglose Individual de Productos Servidos y Eliminación/Cancelación de Ítems en `TableOrderDetailScreen`**.

---

## Componentes Entregados

### 1. Desglose Estructurado de Productos (`_dispatchedItems`)
- [table_order_detail_screen.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/features/tables/screens/table_order_detail_screen.dart):
  - Método `_parseItemsFromConcept(concept)` convierte la comanda viva de Supabase en una lista de productos estructurados con nombre, cantidad, precio unitario y subtotal.
  - La sección "Rondas Previas / Servidas" renderiza tarjetas/filas individuales para cada producto servido en lugar de un texto estático agrupado.
  - Cada fila incluye un botón de acción directo con ícono de basura (`IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent))`).

### 2. Confirmación y Recálculo Atómico en Supabase
- [table_order_detail_screen.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/features/tables/screens/table_order_detail_screen.dart):
  - Muestra un diálogo de confirmación: `¿Retirar producto?` -> `¿Deseas eliminar [Nombre] de la cuenta de la mesa?`.
  - Si quedan productos (`newTotal > 0`):
    - Ejecuta un `UPDATE` en Supabase actualizando `amount` al nuevo saldo (ej. Pizza $120 + Cerveza $65 -> se elimina Cerveza -> nuevo saldo $120.00) y `concept` con los ítems restantes.
    - Notifica a `TableService.notifyListeners()`, actualizando al instante la barra fija inferior y el mapa de mesas.
  - Si se eliminan todos los productos de la mesa (`newTotal == 0`):
    - Marca el cobro como cancelado (`status = 'cancelled'`) en `charges`.
    - Actualiza `restaurant_tables.status` a `'available'`.
    - Llama a `Navigator.pop(context)`, regresando suavemente al mapa de mesas con la mesa tornada en verde ("Disponible").

---

## Verification Summary

### Análisis Estático (`analyze_file`)
- `table_order_detail_screen.dart`: 0 errores / 0 advertencias
- `charge_service.dart`: 0 errores / 0 advertencias

### Pruebas Unitarias (`flutter test`)
- Comando: `flutter test test/features/charge_test.dart test/features/printer_test.dart test/features/cash_cut_test.dart test/features/shift_test.dart test/features/shift_policy_test.dart test/features/tables_rbac_test.dart test/features/table_charging_test.dart test/features/menu_catalog_test.dart test/features/pre_add_dialog_test.dart test/features/table_order_test.dart test/features/printer_precheck_test.dart test/features/atomic_ticket_test.dart test/features/order_consolidation_test.dart test/features/relational_persistence_test.dart test/features/uuid_validation_test.dart test/features/waiter_sanitization_test.dart test/features/zone_uuid_test.dart test/features/table_parsing_test.dart test/features/round_math_test.dart test/features/item_cancellation_test.dart`
- Resultado: `00:11 +38: All tests passed!` (100% de pruebas aprobadas).
