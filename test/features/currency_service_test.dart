import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/core/services/currency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurrencyService USD Cross-Border Spread Tests', () {
    test('Calculates effective USD rate with +10% commercial spread correctly', () {
      final currency = CurrencyService.instance;

      expect(currency.baseUsdRate, 20.00);
      expect(currency.effectiveUsdRate, 22.00); // 20.00 * 1.10 = 22.00
    });

    test('Converts MXN amount to USD correctly using effective rate', () {
      final currency = CurrencyService.instance;

      // 220 MXN / 22.00 effective rate = 10.00 USD
      final convertedUsd = currency.convertMxnToUsd(220.0);
      expect(convertedUsd, 10.00);
    });

    test('Toggles USD currency selection state', () {
      final currency = CurrencyService.instance;
      expect(currency.isUsdSelected, isFalse);

      bool notified = false;
      currency.addListener(() {
        notified = true;
      });

      currency.toggleCurrency();

      expect(notified, isTrue);
      expect(currency.isUsdSelected, isTrue);

      // Toggle back to MXN
      currency.toggleCurrency();
      expect(currency.isUsdSelected, isFalse);
    });
  });
}
