import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/services/currency_service.dart';

/// Paletas de color para la pantalla LCD
enum LcdTheme {
  paleMint,      // Verde menta / salvia claro retro
  classicOlive,  // Verde oliva militar original
  amberGold,     // Ámbar vintage
}

/// Tipografías digitales disponibles para el monto
enum LcdTypography {
  segmentMatrix, // Bloques segmentados con cero cortado
  modernItalic,  // Itálica gruesa en azul marino profundo
  classicMono,   // Monospace estándar
}

class AmountDisplay extends StatelessWidget {
  final double amount;
  final String rawInput;
  final String? expression;
  final List<Map<String, dynamic>>? orderItems;
  final int? lastModifiedIndex;
  final Function(int)? onRemoveItem;
  final VoidCallback? onTapTables;
  final VoidCallback? onTapPrinter;
  final VoidCallback? onTapHistory;
  final LcdTheme? themeOverride;
  final LcdTypography? typographyOverride;

  /// Notificador global de color LCD
  static final ValueNotifier<LcdTheme> themeNotifier =
      ValueNotifier<LcdTheme>(LcdTheme.paleMint);

  /// Notificador global de tipografía LCD
  static final ValueNotifier<LcdTypography> typographyNotifier =
      ValueNotifier<LcdTypography>(LcdTypography.segmentMatrix);

  const AmountDisplay({
    super.key,
    required this.amount,
    required this.rawInput,
    this.expression,
    this.orderItems,
    this.lastModifiedIndex,
    this.onRemoveItem,
    this.onTapTables,
    this.onTapPrinter,
    this.onTapHistory,
    this.themeOverride,
    this.typographyOverride,
  });

  /// Alterna cíclicamente entre los colores disponibles
  static void cycleTheme() {
    switch (themeNotifier.value) {
      case LcdTheme.paleMint:
        themeNotifier.value = LcdTheme.classicOlive;
        break;
      case LcdTheme.classicOlive:
        themeNotifier.value = LcdTheme.amberGold;
        break;
      case LcdTheme.amberGold:
        themeNotifier.value = LcdTheme.paleMint;
        break;
    }
  }

  /// Alterna cíclicamente entre los estilos tipográficos
  static void cycleTypography() {
    switch (typographyNotifier.value) {
      case LcdTypography.segmentMatrix:
        themeNotifier.value = LcdTheme.classicOlive;
        typographyNotifier.value = LcdTypography.modernItalic;
        break;
      case LcdTypography.modernItalic:
        typographyNotifier.value = LcdTypography.classicMono;
        break;
      case LcdTypography.classicMono:
        typographyNotifier.value = LcdTypography.segmentMatrix;
        break;
    }
  }

  String _formatMxn(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  String _formatUsd(double val) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2).format(val);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLocale.instance,
        ThemeService.instance,
        CurrencyService.instance,
        themeNotifier,
        typographyNotifier,
      ]),
      builder: (context, _) {
        final currency = CurrencyService.instance;
        final currentTheme = themeOverride ?? themeNotifier.value;
        final currentTypo = typographyOverride ?? typographyNotifier.value;

        // 1. Colores de pantalla por tema
        late final Color displayBgStart;
        late final Color displayBgEnd;
        late final Color defaultTextColor;
        late final Color borderColor;

        switch (currentTheme) {
          case LcdTheme.paleMint:
            displayBgStart = const Color(0xFFBACBB2);
            displayBgEnd = const Color(0xFFA5B99D);
            defaultTextColor = const Color(0xFF121E12);
            borderColor = const Color(0xFF41533C);
            break;
          case LcdTheme.classicOlive:
            displayBgStart = const Color(0xFF90A389);
            displayBgEnd = const Color(0xFF7A8D73);
            defaultTextColor = const Color(0xFF0C143B);
            borderColor = const Color(0xFF3A4A35);
            break;
          case LcdTheme.amberGold:
            displayBgStart = const Color(0xFFE2B056);
            displayBgEnd = const Color(0xFFC79336);
            defaultTextColor = const Color(0xFF261604);
            borderColor = const Color(0xFF6B480C);
            break;
        }

        // 2. Configuración tipográfica
        late final TextStyle mainAmountStyle;
        late final TextStyle ghostAmountStyle;

        switch (currentTypo) {
          case LcdTypography.segmentMatrix:
            mainAmountStyle = TextStyle(
              fontFamily: 'Courier',
              fontFamilyFallback: const ['monospace'],
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.normal,
              color: const Color(0xFF0A120A),
              letterSpacing: 2.2,
              fontFeatures: const [
                FontFeature.slashedZero(),
                FontFeature.tabularFigures(),
              ],
            );
            ghostAmountStyle = TextStyle(
              fontFamily: 'Courier',
              fontFamilyFallback: const ['monospace'],
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.normal,
              color: defaultTextColor.withOpacity(0.08),
              letterSpacing: 2.2,
            );
            break;

          case LcdTypography.modernItalic:
            mainAmountStyle = const TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF0C1B6E),
              letterSpacing: 1.0,
            );
            ghostAmountStyle = TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: defaultTextColor.withOpacity(0.09),
              letterSpacing: 1.0,
            );
            break;

          case LcdTypography.classicMono:
            mainAmountStyle = TextStyle(
              fontFamily: 'monospace',
              fontSize: 46,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.normal,
              color: defaultTextColor,
              letterSpacing: 1.0,
            );
            ghostAmountStyle = TextStyle(
              fontFamily: 'monospace',
              fontSize: 46,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.normal,
              color: defaultTextColor.withOpacity(0.08),
              letterSpacing: 1.0,
            );
            break;
        }

        final isUsd = currency.isUsdSelected;
        final displayAmountStr = isUsd
            ? '${_formatUsd(currency.convertMxnToUsd(amount))} USD'
            : _formatMxn(amount);

        final hasItems = orderItems != null && orderItems!.isNotEmpty;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
          padding: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: const Color(0xFF22252A),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 4),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [displayBgStart, displayBgEnd],
              ),
              borderRadius: BorderRadius.circular(11.0),
              border: Border.all(color: borderColor, width: 2.0),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 2),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Íconos verticales a la izquierda
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, right: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onTapTables != null)
                        InkWell(
                          onTap: onTapTables,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(Icons.table_restaurant_rounded, size: 24, color: defaultTextColor),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (onTapPrinter != null)
                        InkWell(
                          onTap: onTapPrinter,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(Icons.print_rounded, size: 24, color: defaultTextColor),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (onTapHistory != null)
                        InkWell(
                          onTap: onTapHistory,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(Icons.receipt_long_rounded, size: 24, color: defaultTextColor),
                          ),
                        ),
                    ],
                  ),
                ),

                // Contenido derecho
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Encabezado superior
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: cycleTheme,
                            child: Row(
                              children: [
                                Text(
                                  tr('amount_to_charge'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: defaultTextColor.withOpacity(0.85),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.palette_outlined,
                                  size: 13,
                                  color: defaultTextColor.withOpacity(0.60),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => currency.toggleCurrency(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🇺🇸', style: TextStyle(fontSize: 9)),
                                  const SizedBox(width: 3),
                                  const Text(
                                    'USD',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // BANDEJA DE DESGLOSE CON ALTURA FIJA (72 px)
                      // Mantiene invariante la altura total del LCD para evitar brincos en la cuadrícula inferior
                      Container(
                        height: 72,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: defaultTextColor.withOpacity(0.18)),
                        ),
                        child: hasItems
                            ? ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: orderItems!.length,
                                itemBuilder: (context, idx) {
                                  final it = orderItems![idx];
                                  final sub = ((it['subtotal'] ?? it['price']) as num).toDouble();
                                  final isHighlighted = idx == lastModifiedIndex;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    margin: const EdgeInsets.symmetric(vertical: 1.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isHighlighted
                                          ? defaultTextColor.withOpacity(0.18)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${it['quantity']}x ${it['name']}',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                                              color: defaultTextColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '\$${sub.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: defaultTextColor,
                                          ),
                                        ),
                                        if (onRemoveItem != null) ...[
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => onRemoveItem!(idx),
                                            child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              )
                            : (expression != null && expression!.isNotEmpty)
                                ? Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: Text(
                                        expression!,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: defaultTextColor.withOpacity(0.75),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 14,
                                          color: defaultTextColor.withOpacity(0.25),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocale.instance.isSpanish
                                              ? 'Sin consumos en orden'
                                              : 'No items in order',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: defaultTextColor.withOpacity(0.30),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),

                      // Monto Principal
                      GestureDetector(
                        onTap: cycleTypography,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Text(
                                isUsd ? '888,888.88 USD' : '888,888.88',
                                style: ghostAmountStyle,
                              ),
                              Text(
                                displayAmountStr,
                                style: mainAmountStyle,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Línea fija para tasa de cambio USD (evita variaciones verticales)
                      SizedBox(
                        height: 14,
                        child: isUsd
                            ? Text(
                                '1 USD = \$${currency.effectiveUsdRate.toStringAsFixed(2)} MXN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: defaultTextColor.withOpacity(0.85),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}