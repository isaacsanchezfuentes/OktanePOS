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
    Widget content;
    Color backgroundColor = const Color(0xFFFFFFFF); // BLANCO PURO OBLIGATORIO en todos los temas
    Color foregroundColor = const Color(0xFF111827); // NEGRO GRAFITO PROFUNDO OBLIGATORIO
    Border border = Border.all(color: const Color(0xFFCBD5E1), width: 1.5);

    switch (key) {
      case 'BACKSPACE':
        content = const Icon(Icons.backspace_outlined, size: 22, color: Colors.white);
        backgroundColor = ThemeService.keyDEL; // Naranja Vivo Casio (0xFFEA580C)
        foregroundColor = Colors.white;
        border = Border.all(color: Colors.transparent);
        break;
      case 'CLEAR':
        content = const Text(
          'C',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        );
        backgroundColor = ThemeService.keyC; // Rojo Intenso Casio (0xFFDC2626)
        foregroundColor = Colors.white;
        border = Border.all(color: Colors.transparent);
        break;
      case 'AC':
        content = const Text(
          'AC',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        );
        backgroundColor = ThemeService.keyAC; // Verde Esmeralda Casio (0xFF16A34A)
        foregroundColor = Colors.white;
        border = Border.all(color: Colors.transparent);
        break;
      default:
        content = Text(
          key,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        );
    }

    return Material(
      color: backgroundColor,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onKeyTap(key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border,
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: foregroundColor),
            child: IconTheme(
              data: IconThemeData(color: foregroundColor),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
