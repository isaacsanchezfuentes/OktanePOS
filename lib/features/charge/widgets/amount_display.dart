import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/services/currency_service.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final String rawInput;
  final VoidCallback? onTapTables;
  final VoidCallback? onTapPrinter;
  final VoidCallback? onTapHistory;

  const AmountDisplay({
    super.key,
    required this.amount,
    required this.rawInput,
    this.onTapTables,
    this.onTapPrinter,
    this.onTapHistory,
  });

  String _formatMxn(double val) {
    return NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    ).format(val);
  }

  String _formatUsd(double val) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    ).format(val);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLocale.instance, ThemeService.instance, CurrencyService.instance]),
      builder: (context, _) {
        final currency = CurrencyService.instance;
        const displayBgStart = Color(0xFFC4D8C2);
        const displayBgEnd = Color(0xFFB2CAB0);
        const displayText = Color(0xFF152013); // Tinta LCD oscura sólida

        final isUsd = currency.isUsdSelected;
        final displayAmountStr = isUsd
            ? '${_formatUsd(currency.convertMxnToUsd(amount))} USD'
            : _formatMxn(amount);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2226),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 4),
              BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, -1), blurRadius: 1),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [displayBgStart, displayBgEnd],
              ),
              borderRadius: BorderRadius.circular(13.0),
              border: Border.all(
                color: const Color(0xFF4A5C48),
                width: 1.5,
              ),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Top Header Row: 3 Action Icons in Single Horizontal Row on Left + Label & Currency Toggle on Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: 3 Action Icons in Single Horizontal Row with Comfortable Touch Targets
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onTapPrinter != null)
                          InkWell(
                            onTap: onTapPrinter,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.print_rounded,
                                size: 28,
                                color: displayText,
                              ),
                            ),
                          ),
                        if (onTapPrinter != null) const SizedBox(width: 8),
                        if (onTapHistory != null)
                          InkWell(
                            onTap: onTapHistory,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 28,
                                color: displayText,
                              ),
                            ),
                          ),
                        if (onTapHistory != null) const SizedBox(width: 8),
                        if (onTapTables != null)
                          InkWell(
                            onTap: onTapTables,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.table_restaurant_rounded,
                                size: 28,
                                color: displayText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right Header: Label + Currency Toggle Chip
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('amount_to_charge'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: displayText.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Clean Currency Toggle Chip (MXN / USD)
                      InkWell(
                        onTap: () => currency.toggleCurrency(),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isUsd ? const Color(0xFF0F172A) : displayText.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isUsd ? '🇺🇸 USD' : '🇲🇽 MXN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isUsd ? Colors.white : displayText,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.swap_horiz,
                                size: 13,
                                color: isUsd ? Colors.white : displayText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Liquid Crystal Panel Horizontal Divider Line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                width: double.infinity,
                height: 1.2,
                color: const Color(0xFF152013).withValues(alpha: 0.20),
              ),
              const SizedBox(height: 4),
              // Stack of Ghost Segments '888,888.88' (without $) + Active Value
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  // Inactive LCD ghost digits background (SIN SIGNO $)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      isUsd ? '88,888.88 USD' : '888,888.88',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: displayText.withValues(alpha: 0.08),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  // Active LCD Value in Solid Dark Ink
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      displayAmountStr,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: displayText,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
              if (isUsd) ...[
                const SizedBox(height: 2),
                Text(
                  'Tasa de Cambio: 1 USD = \$${currency.effectiveUsdRate.toStringAsFixed(2)} MXN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: displayText.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
        );
      },
    );
  }
}
