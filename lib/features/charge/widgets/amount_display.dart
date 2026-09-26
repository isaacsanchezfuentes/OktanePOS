import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/theme/theme_service.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final String rawInput;

  const AmountDisplay({
    super.key,
    required this.amount,
    required this.rawInput,
  });

  String get _formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLocale.instance, ThemeService.instance]),
      builder: (context, _) {
        final theme = ThemeService.instance;
        final displayBg = theme.displayBg;
        final displayText = theme.displayText;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: displayBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: displayText.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('amount_to_charge'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: displayText.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: displayText.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MXN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: displayText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _formattedAmount,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: displayText,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
