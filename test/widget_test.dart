import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/ui/screens/login_screen.dart';
import 'setup_test_mocks.dart';

void main() {
  setupTestMocks();

  testWidgets('Oktane POS LoginScreen renders brand header and login fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Verify brand header RichText and subtitle chip
    final richTextFinder = find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText().contains('Oktane POS'),
    );
    expect(richTextFinder, findsOneWidget);

    expect(find.text('SISTEMA DE COMANDAS & COBRO'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}
