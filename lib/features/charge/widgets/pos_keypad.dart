import 'package:flutter/material.dart';

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
  }

  Widget _buildKeyButton(BuildContext context, String key) {
    Widget content;
    Color? backgroundColor;
    Color foregroundColor = Colors.black87;

    switch (key) {
      case 'BACKSPACE':
        content = const Icon(Icons.backspace_outlined, size: 24);
        backgroundColor = Colors.grey[200];
        foregroundColor = Colors.red[700]!;
        break;
      case 'CLEAR':
        content = const Text(
          'C',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        );
        backgroundColor = Colors.red[50];
        foregroundColor = Colors.red[700]!;
        break;
      default:
        content = Text(
          key,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        );
        backgroundColor = Colors.white;
        foregroundColor = Colors.blueGrey[900]!;
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
              color: Colors.grey[300]!,
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
