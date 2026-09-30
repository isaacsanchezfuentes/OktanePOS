import 'package:flutter/material.dart';
import 'package:oktane_pos/core/localization/app_locale.dart';

class PosKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final bool isScientificMode;

  const PosKeypad({
    super.key,
    required this.onKeyTap,
    this.isScientificMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isScientificMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        child: Column(
          children: [
            // Fila 1 (Superior): CUENTA TOTAL, ×, ÷, ⌫ (borrar)
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildKeyButton('TOTAL', isTotal: true)),
                  Expanded(child: _buildKeyButton('×', isOp: true)),
                  Expanded(child: _buildKeyButton('÷', isOp: true)),
                  Expanded(child: _buildKeyButton('⌫')),
                ],
              ),
            ),
            // Bloque numérico principal: filas 2 a 5 con la columna derecha ordenada
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  // Fila 2: 7, 8, 9, C
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildKeyButton('7')),
                        Expanded(child: _buildKeyButton('8')),
                        Expanded(child: _buildKeyButton('9')),
                        Expanded(child: _buildKeyButton('C')),
                      ],
                    ),
                  ),
                  // Fila 3: 4, 5, 6, +
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildKeyButton('4')),
                        Expanded(child: _buildKeyButton('5')),
                        Expanded(child: _buildKeyButton('6')),
                        Expanded(child: _buildKeyButton('+', isOp: true)),
                      ],
                    ),
                  ),
                  // Fila 4: 1, 2, 3, -
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildKeyButton('1')),
                        Expanded(child: _buildKeyButton('2')),
                        Expanded(child: _buildKeyButton('3')),
                        Expanded(child: _buildKeyButton('-', isOp: true)),
                      ],
                    ),
                  ),
                  // Fila 5: . (col 1), 0 (col 2), COBRO MÚLTIPLE (cols 3 y 4 - ancho doble)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 1, child: _buildKeyButton('.')),
                        Expanded(flex: 1, child: _buildKeyButton('0')),
                        Expanded(
                          flex: 2,
                          child: _buildKeyButton('COBRO_MULTIPLE', isMulti: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Modo Numérico Estándar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildColumn(['7', '4', '1', '.'])),
          Expanded(child: _buildColumn(['8', '5', '2', '0'])),
          Expanded(child: _buildColumn(['9', '6', '3', '00'])),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 1, child: _buildKeyButton('⌫')),
                Expanded(flex: 1, child: _buildKeyButton('C')),
                Expanded(flex: 2, child: _buildKeyButton('COBRO_MULTIPLE', isMulti: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(List<String> keys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: keys.map((key) => Expanded(flex: 1, child: _buildKeyButton(key))).toList(),
    );
  }

  Widget _buildKeyButton(
    String key, {
    bool isEnter = false,
    bool isOp = false,
    bool isTotal = false,
    bool isMulti = false,
  }) {
    final isClear = key == 'C';
    final isBack = key == '⌫';
    final isMultiPay = key == 'COBRO_MULTIPLE' || isMulti;

    // Acabado de cristal: Verde esmeralda (TOTAL), Azul zafiro (COBRO MÚLTIPLE) y Cristal estándar
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isTotal
          ? [
              const Color(0xFF4ADE80).withOpacity(0.70), // Verde brillante superior
              const Color(0xFF22C55E).withOpacity(0.40), // Verde translúcido
              const Color(0xFF15803D).withOpacity(0.60), // Bisel verde bosque
            ]
          : isMultiPay
              ? [
                  const Color(0xFF60A5FA).withOpacity(0.85), // Azul cielo brillante superior
                  const Color(0xFF2563EB).withOpacity(0.55), // Azul rey translúcido
                  const Color(0xFF1E3A8A).withOpacity(0.75), // Bisel azul marino profundo
                ]
              : isEnter
                  ? [
                      const Color(0xFFB5C4AF).withOpacity(0.55),
                      const Color(0xFF8DA387).withOpacity(0.20),
                      const Color(0xFF5E7358).withOpacity(0.35),
                    ]
                  : [
                      Colors.white.withOpacity(0.55), // Reflejo superior
                      Colors.white.withOpacity(0.06), // Cuerpo transparente
                      Colors.black.withOpacity(0.22), // Sombra inferior
                    ],
      stops: const [0.0, 0.35, 1.0],
    );

    final fontColor = isClear
        ? const Color(0xFFDC2626)
        : isTotal
            ? const Color(0xFF052E16)
            : isMultiPay
                ? Colors.white
                : (isEnter ? const Color(0xFF142412) : const Color(0xFF0F172A));

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (key == '⌫') {
            onKeyTap('BACKSPACE');
          } else if (key == '↵') {
            onKeyTap('=');
          } else {
            onKeyTap(key);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isTotal
                  ? const Color(0xFF166534).withOpacity(0.75)
                  : isMultiPay
                      ? const Color(0xFF1D4ED8).withOpacity(0.85) // Borde azul cobalto
                      : isEnter
                          ? const Color(0xFF5E7358).withOpacity(0.60)
                          : Colors.black.withOpacity(0.28),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                offset: const Offset(1.5, 2.0),
                blurRadius: 2.5,
              ),
            ],
          ),
          child: Center(
            child: isBack
                ? Icon(Icons.backspace_outlined, color: fontColor, size: 22)
                : isTotal
                    ? Text(
                        AppLocale.instance.isSpanish ? 'CUENTA\nTOTAL' : 'BILL\nTOTAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: fontColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: 0.2,
                        ),
                      )
                    : isMultiPay
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.checklist_rtl_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                AppLocale.instance.isSpanish ? 'COBRO\nMÚLTIPLE' : 'SPLIT\nBILL',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            key,
                            style: TextStyle(
                              color: fontColor,
                              fontSize: isOp ? 21 : 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}