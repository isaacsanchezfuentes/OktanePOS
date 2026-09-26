import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';
import 'package:oktane_pos/features/charge/widgets/amount_display.dart';
import 'package:oktane_pos/features/charge/widgets/pos_keypad.dart';
import '../setup_test_mocks.dart';

void main() {
  setupTestMocks();

  group('ChargeModel Unit Tests', () {
    test('ChargeModel toSupabaseJson generates correct pending record map', () {
      final charge = ChargeModel(
        amount: 150.50,
        currency: 'MXN',
        status: 'pending',
        userId: 'user-123-abc',
        concept: 'Mesa 4',
        paymentMethod: 'efectivo',
      );

      final json = charge.toSupabaseJson();

      expect(json['amount'], 150.50);
      expect(json['currency'], 'MXN');
      expect(json['status'], 'pending');
      expect(json['user_id'], 'user-123-abc');
      expect(json['concept'], 'Mesa 4');
      expect(json['payment_method'], 'efectivo');
    });

    test('ChargeModel calculates effectiveTimestamp using updatedAt or fallback to createdAt', () {
      final createdTime = DateTime(2026, 9, 24, 10, 0);
      final updatedTime = DateTime(2026, 9, 24, 10, 15);

      final chargeWithoutUpdated = ChargeModel(
        amount: 50.0,
        userId: 'u1',
        concept: 'Mesa 1',
        paymentMethod: 'efectivo',
        createdAt: createdTime,
      );

      expect(chargeWithoutUpdated.effectiveTimestamp, createdTime);

      final chargeWithUpdated = ChargeModel(
        amount: 50.0,
        userId: 'u1',
        concept: 'Mesa 1',
        paymentMethod: 'efectivo',
        createdAt: createdTime,
        updatedAt: updatedTime,
      );

      expect(chargeWithUpdated.effectiveTimestamp, updatedTime);
    });

    test('ChargeModel summary calculations for paid total and pending count', () {
      final charges = [
        const ChargeModel(amount: 100.0, userId: 'u1', concept: 'c1', paymentMethod: 'efectivo', status: 'paid'),
        const ChargeModel(amount: 50.0, userId: 'u1', concept: 'c2', paymentMethod: 'qr', status: 'pending'),
        const ChargeModel(amount: 25.0, userId: 'u1', concept: 'c3', paymentMethod: 'tarjeta', status: 'pending'),
        const ChargeModel(amount: 200.0, userId: 'u1', concept: 'c4', paymentMethod: 'efectivo', status: 'cancelled'),
      ];

      final totalPaid = charges
          .where((c) => c.status == 'paid')
          .fold(0.0, (sum, c) => sum + c.amount);

      final pendingCount = charges.where((c) => c.status == 'pending').length;

      expect(totalPaid, 100.0);
      expect(pendingCount, 2);
    });
  });

  group('AmountDisplay Widget Tests', () {
    testWidgets('AmountDisplay formats amount correctly as MXN currency', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmountDisplay(
              amount: 12.50,
              rawInput: '12.50',
            ),
          ),
        ),
      );

      expect(find.text('MXN'), findsOneWidget);
      expect(find.text('Monto a cobrar'), findsOneWidget);
      expect(find.text('\$12.50'), findsOneWidget);
    });
  });

  group('PosKeypad Widget Tests', () {
    testWidgets('PosKeypad emits tapped key values correctly', (WidgetTester tester) async {
      String tappedKey = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosKeypad(
              onKeyTap: (key) => tappedKey = key,
            ),
          ),
        ),
      );

      // Tap key '5'
      await tester.tap(find.text('5'));
      expect(tappedKey, '5');

      // Tap key '00'
      await tester.tap(find.text('00'));
      expect(tappedKey, '00');

      // Tap key 'C'
      await tester.tap(find.text('C'));
      expect(tappedKey, 'CLEAR');
    });
  });
}
