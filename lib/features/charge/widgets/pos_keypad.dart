import 'package:flutter/material.dart';
import '../../../core/theme/theme_service.dart';

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
    final List<List<String>> scientificOperators = [
      ['×', '÷', '+', '-'],
    ];

    final List<List<String>> standardKeys = isScientificMode
        ? [
            ['7', '8', '9', '×10'],
            ['4', '5', '6', 'CLEAR'],
            ['1', '2', '3', 'BACKSPACE'],
            ['.', '0', 'Ans', '='],
          ]
        : [
            ['7', '8', '9', '×10'],
            ['4', '5', '6', 'CLEAR'],
            ['1', '2', '3', 'BACKSPACE'],
            ['.', '0'],
          ];

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Column(
            children: [
              if (isScientificMode) ...[
                ...scientificOperators.map((row) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: row.map((key) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _buildKeyButton(context, key),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }),
              ],
              ...standardKeys.map((row) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: row.map((key) {
                        final isZeroKeyInLastRow = key == '0' && row.length == 2;
                        return Expanded(
                          flex: isZeroKeyInLastRow ? 3 : 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildKeyButton(context, key),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyButton(BuildContext context, String key) {
    final isClear = key == 'CLEAR' || key == 'CA';
    final isBack = key == 'BACKSPACE' || key == 'DEL';
    final isOp = key == '+' || key == '-' || key == '×' || key == '÷' || key == '=' || key == 'Ans' || key == '×10';

    final border = isClear
        ? Border.all(color: const Color(0xFFDC2626), width: 1.4)
        : isBack
            ? Border.all(color: const Color(0xFFD97706), width: 1.3)
            : isOp
                ? Border.all(color: const Color(0xFF2563EB), width: 1.2)
                : Border.all(color: const Color(0xFF64748B), width: 1.1);

    final fontColor = isClear
        ? const Color(0xFFDC2626)
        : isBack
            ? const Color(0xFFD97706)
            : isOp
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onKeyTap(key),
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0x22000000),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent, // Cero relleno oscuro
            borderRadius: BorderRadius.circular(8),
            border: border,
            boxShadow: const [
              // Capa oscura: Sombra de caída que hunde la tecla en el chasis
              BoxShadow(color: Color(0x40000000), offset: Offset(0, 2.5), blurRadius: 2.5),
              // Capa clara: Reflejo de luz en la arista superior
              BoxShadow(color: Color(0x80FFFFFF), offset: Offset(0, -1), blurRadius: 1),
            ],
          ),
          child: isBack
              ? Icon(Icons.backspace_outlined, color: fontColor, size: 22)
              : Text(
                  key == 'CLEAR' ? 'C' : key,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: isOp ? 22 : 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}
