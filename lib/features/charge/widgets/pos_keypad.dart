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
    final theme = ThemeService.instance;
    Widget content;
    Color backgroundColor = theme.padButtonBg;
    Color foregroundColor = theme.padButtonText;

    switch (key) {
      case 'BACKSPACE':
        content = const Icon(Icons.backspace_outlined, size: 24);
        backgroundColor = theme.padButtonBg;
        foregroundColor = ThemeService.keyDEL; // Ámbar/Naranja Casio (0xFFF59E0B)
        break;
      case 'CLEAR':
        content = const Text(
          'C',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        );
        backgroundColor = ThemeService.keyC.withValues(alpha: 0.15); // Alerta suave
        foregroundColor = ThemeService.keyC; // Rojo suave Casio (0xFFEF4444)
        break;
      default:
        content = Text(
          key,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        );
    }

    return Material(
      color: backgroundColor,
      elevation: key == 'BACKSPACE' || key == 'CLEAR' ? 1 : 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onKeyTap(key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!.withValues(alpha: 0.3),
              width: 0.8,
            ),
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
