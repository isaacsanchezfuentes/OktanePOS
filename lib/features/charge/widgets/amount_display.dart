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
        final theme = ThemeService.instance;
        final currency = CurrencyService.instance;
        final displayBg = theme.displayBg;
        final displayText = theme.displayText;

        final isUsd = currency.isUsdSelected;
        final displayAmountStr = isUsd
            ? '${_formatUsd(currency.convertMxnToUsd(amount))} USD'
            : _formatMxn(amount);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: displayBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: displayText.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicadores digitales retro e accesos rápidos (Mesas, Impresora, Historial)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (onTapTables != null)
                            InkWell(
                              onTap: onTapTables,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                child: Icon(
                                  Icons.table_restaurant,
                                  size: 22,
                                  color: displayText,
                                ),
                              ),
                            ),
                          if (onTapPrinter != null)
                            InkWell(
                              onTap: onTapPrinter,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                child: Icon(
                                  Icons.print_outlined,
                                  size: 22,
                                  color: displayText,
                                ),
                              ),
                            ),
                          if (onTapHistory != null)
                            InkWell(
                              onTap: onTapHistory,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                child: Icon(
                                  Icons.receipt_long,
                                  size: 22,
                                  color: displayText,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            tr('amount_to_charge'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: displayText.withValues(alpha: 0.75),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Conmutador de moneda limpio (MXN / USD)
                  InkWell(
                    onTap: () => currency.toggleCurrency(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUsd ? const Color(0xFF2563EB) : displayText.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isUsd ? '🇺🇸 USD' : '🇲🇽 MXN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUsd ? Colors.white : displayText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_horiz,
                            size: 14,
                            color: isUsd ? Colors.white : displayText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Stack de segmentos ceros inactivos + importe real activo
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  // Ceros fantasma apagados en fondo (sin signo $)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      isUsd ? '88,888.88 USD' : '888,888.88',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: displayText.withValues(alpha: 0.08),
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  // Valor activo en tinta negra sólida LCD
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      displayAmountStr,
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
        );
      },
    );
  }
}
