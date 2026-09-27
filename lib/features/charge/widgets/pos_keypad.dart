import 'package:flutter/material.dart';
import '../../../core/theme/theme_service.dart';

class PosKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;

  const PosKeypad({
    super.key,
    required this.onKeyTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<List<String>> keys = [
      ['1', '2', '3', 'BACKSPACE'],
      ['4', '5', '6', 'CLEAR'],
      ['7', '8', '9', '00'],
      ['.', '0'],
    ];

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: keys.map((row) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
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
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildKeyButton(BuildContext context, String key) {
    final isClear = key == 'CLEAR';
    final isBack = key == 'BACKSPACE';

    final border = isClear
        ? Border.all(color: const Color(0xFFDC2626), width: 1.4)
        : isBack
            ? Border.all(color: const Color(0xFFD97706), width: 1.3)
            : Border.all(color: const Color(0xFF64748B), width: 1.1);

    final fontColor = isClear
        ? const Color(0xFFDC2626)
        : isBack
            ? const Color(0xFFD97706)
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
                  isClear ? 'C' : key,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}
