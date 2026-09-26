import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends ChangeNotifier {
  static final CurrencyService instance = CurrencyService._internal();

  factory CurrencyService() => instance;

  CurrencyService._internal(); // Pure synchronous no-op constructor!

  static const double defaultBaseUsdRate = 20.00;
  static const double crossBorderSpread = 1.10; // +10% commercial spread

  double _baseUsdRate = defaultBaseUsdRate;
  bool _isUsdSelected = false;

  bool get isUsdSelected => _isUsdSelected;

  /// Base rate before spread
  double get baseUsdRate => _baseUsdRate;

  /// Immediate synchronous effective rate constant (20.00 * 1.10 = 22.00)
  double get effectiveUsdRate => _baseUsdRate * crossBorderSpread;

  /// Pure non-blocking background rate update (unawaited / fire-and-forget)
  void updateRateInBackground() {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedRate = prefs.getDouble('cached_usd_rate');
        if (cachedRate != null && cachedRate > 0 && cachedRate != _baseUsdRate) {
          _baseUsdRate = cachedRate;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('ℹ️ CurrencyService background update skipped: $e');
      }
    });
  }

  void toggleCurrency() {
    _isUsdSelected = !_isUsdSelected;
    notifyListeners();
  }

  /// Converts MXN amount to USD using effective rate
  double convertMxnToUsd(double amountMxn) {
    if (effectiveUsdRate <= 0) return 0.0;
    return amountMxn / effectiveUsdRate;
  }
}
