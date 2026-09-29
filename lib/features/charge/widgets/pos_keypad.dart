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
      // Modo Calculadora: Botón verdoso CUENTA TOTAL en la esquina superior izquierda
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        child: Column(
          children: [
            // Fila superior: CUENTA TOTAL y operadores matemáticos
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildKeyButton('TOTAL', isTotal: true)),
                  Expanded(child: _buildKeyButton('-', isOp: true)),
                  Expanded(child: _buildKeyButton('×', isOp: true)),
                  Expanded(child: _buildKeyButton('÷', isOp: true)),
                ],
              ),
            ),
            // Bloque numérico principal con Ans y el botón + a la derecha
            Expanded(
              flex: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildColumn(['7', '4', '1', '.'])),
                  Expanded(child: _buildColumn(['8', '5', '2', '0'])),
                  Expanded(child: _buildColumn(['9', '6', '3', 'Ans'])),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 1, child: _buildKeyButton('⌫')),
                        Expanded(flex: 1, child: _buildKeyButton('C')),
                        Expanded(flex: 1, child: _buildKeyButton('+', isOp: true)),
                        Expanded(flex: 1, child: _buildKeyButton('=', isEnter: true)),
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
                Expanded(flex: 2, child: _buildKeyButton('↵', isEnter: true)),
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
  }) {
    final isClear = key == 'C';
    final isBack = key == '⌫';

    // Acabado de cristal: Verdoso esmeralda para CUENTA TOTAL, salvia para ENTER y cristal para teclas estándar
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isTotal
          ? [
              const Color(0xFF4ADE80).withOpacity(0.70), // Verde brillante superior
              const Color(0xFF22C55E).withOpacity(0.40), // Verde medio translúcido
              const Color(0xFF15803D).withOpacity(0.60), // Bisel verde bosque inferior
            ]
          : isEnter
              ? [
                  const Color(0xFFB5C4AF).withOpacity(0.55), // Tinte verde salvia transparente
                  const Color(0xFF8DA387).withOpacity(0.20),
                  const Color(0xFF5E7358).withOpacity(0.35),
                ]
              : [
                  Colors.white.withOpacity(0.55), // Reflejo de luz superior izquierda
                  Colors.white.withOpacity(0.06), // Cuerpo transparente translúcido
                  Colors.black.withOpacity(0.22), // Sombra de bisel inferior derecha
                ],
      stops: const [0.0, 0.35, 1.0],
    );

    final fontColor = isClear
        ? const Color(0xFFDC2626)
        : isTotal
            ? const Color(0xFF052E16) // Verde profundo de alto contraste
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
                : isEnter && key == '↵'
                    ? Icon(Icons.keyboard_return_rounded, color: fontColor, size: 26)
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
                        : Text(
                            key,
                            style: TextStyle(
                              color: fontColor,
                              fontSize: isOp ? 21 : (isEnter ? 24 : 22),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}