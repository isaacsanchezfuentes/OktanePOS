# Walkthrough - POS Quick Charge, Official Slate Industrial Design System Palette

Se implementó la **Paleta Oficial del Design System "Slate Industrial"** en `TableTheme` y se aplicaron las reglas de estilo en `TablesMapScreen`.

---

## Componentes Entregados

### 1. Tokens de Diseño del Design System (`TableTheme`)
- [table_theme.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/features/tables/theme/table_theme.dart):
  - **Capas (bg-950 a bg-700)**:
    - `bg950`: `#0D1116` (Fundo raíz de la app)
    - `bg900`: `#151A21` (Barra de zonas / contenido principal)
    - `bg800`: `#1E252D` (Tarjetas de mesas / paneles / tickets)
    - `bg700`: `#2A333D` (Elevado / hover)
    - `border`: `#3A454F` (Divisores sutiles)
    - `borderStrong`: `#4C5964` (Bordes de foco)
  - **Tipografía**:
    - `textPrimary`: `#ECEFF2` (Texto principal, montos)
    - `textSecondary`: `#9AA5AF` (Etiquetas, aforo, texto de apoyo)
    - `textMuted`: `#667079` (Placeholders)
  - **Acento y Semánticos**:
    - `accent`: `#2E90E5` (Acción principal: cobrar / azul cobranza)
    - `accentHover`: `#1D6FBD`
    - `success`: `#3FB27F` (Mesa disponible / pagado)
    - `warning`: `#E0A73B` (Mesa ocupada / borrador industrial)
    - `danger`: `#E5484D` (Anulado / error)
  - **Mapeos Semánticos**:
    - `floorBackground = bg950`
    - `zoneBarBackground = bg900`
    - `cardSurface = bg800`

### 2. Aplicación de Reglas de Diseño en `TablesMapScreen`
- [tables_map_screen.dart](file:///C:/Users/PC/Shamanica/AndroidStudioProjects/oktane-pos/lib/features/tables/screens/tables_map_screen.dart):
  - Lienzo del salón en `bg950` (#0D1116).
  - Barra de zonas e indicadores en `bg900` (#151A21).
  - Tarjetas de mesa renderizadas en `bg800` (#1E252D) o con color de estado semántico (`freeBg`, `occupiedBg`, `billedBg`).
  - Etiquetas de estado de orden ("OCUPADA") con `warning` (#E0A73B) y montos/encabezados en `textPrimary` (#ECEFF2).

---

## Verification Summary

### Pruebas Unitarias (`flutter test`)
- Comando: `flutter test test/widget_test.dart test/features/charge_test.dart test/features/printer_test.dart test/features/cash_cut_test.dart test/features/shift_test.dart test/features/shift_policy_test.dart test/features/tables_rbac_test.dart test/features/table_charging_test.dart test/features/menu_catalog_test.dart test/features/pre_add_dialog_test.dart test/features/table_order_test.dart test/features/printer_precheck_test.dart test/features/atomic_ticket_test.dart test/features/order_consolidation_test.dart test/features/relational_persistence_test.dart test/features/uuid_validation_test.dart test/features/waiter_sanitization_test.dart test/features/zone_uuid_test.dart test/features/table_parsing_test.dart test/features/round_math_test.dart test/features/item_cancellation_test.dart test/features/singleton_table_service_test.dart test/features/calculator_table_bridge_test.dart test/features/language_toggle_test.dart test/features/table_elapsed_timer_test.dart`
- Resultado: **`00:37 +45: All tests passed!`** (100% de 45 pruebas aprobadas).
