import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/core/localization/app_locale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quick Language Toggle (ES/EN) Tests', () {
    test('Toggles language between es and en and updates translation strings', () {
      final appLocale = AppLocale.instance;

      // Default should be 'es'
      expect(appLocale.currentLang, 'es');
      expect(tr('amount_to_charge'), 'Monto a cobrar');
      expect(tr('table_location'), 'Mesa / Ubicación');
      expect(tr('waiter_service'), 'Mesero / Atención');
      expect(tr('view_table'), 'Ver Mesa');
      expect(tr('take_full_order_view_table'), 'TOMAR PEDIDO COMPLETO / VER MESA');
      expect(tr('send_to_kitchen'), 'MANDAR A PREPARACIÓN');
      expect(tr('charge'), 'COBRAR');

      // Toggle to 'en'
      bool notified = false;
      appLocale.addListener(() {
        notified = true;
      });

      appLocale.toggle();

      expect(notified, isTrue);
      expect(appLocale.currentLang, 'en');
      expect(tr('amount_to_charge'), 'Amount to charge');
      expect(tr('table_location'), 'Table / Location');
      expect(tr('waiter_service'), 'Server / Attendant');
      expect(tr('view_table'), 'View Table');
      expect(tr('take_full_order_view_table'), 'TAKE FULL ORDER / VIEW TABLE');
      expect(tr('send_to_kitchen'), 'SEND TO KITCHEN');
      expect(tr('charge'), 'CHARGE');

      // Toggle back to 'es'
      appLocale.toggle();
      expect(appLocale.currentLang, 'es');
      expect(tr('amount_to_charge'), 'Monto a cobrar');
    });
  });
}
