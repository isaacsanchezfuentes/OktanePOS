import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/cash_cut/models/shift_model.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';

void main() {
  group('ShiftModel Unit Tests', () {
    test('ShiftModel generates correct insert and close JSON maps', () {
      final now = DateTime(2026, 9, 24, 10, 0);
      final shift = ShiftModel(
        id: 'shift-uuid-123',
        userId: 'user-uuid-456',
        openedAt: now,
        initialCash: 500.0,
        totalSales: 1500.0,
        cashSales: 800.0,
        cardSales: 400.0,
        qrSales: 300.0,
        drawerCounted: 1300.0,
        difference: 0.0,
        status: 'open',
      );

      final insertJson = shift.toSupabaseInsertJson();
      expect(insertJson['user_id'], 'user-uuid-456');
      expect(insertJson['initial_cash'], 500.0);
      expect(insertJson['status'], 'open');

      final closeJson = shift.toSupabaseCloseJson();
      expect(closeJson['status'], 'closed');
      expect(closeJson['total_sales'], 1500.0);
      expect(closeJson['cash_sales'], 800.0);
      expect(closeJson['drawer_counted'], 1300.0);
      expect(closeJson['difference'], 0.0);
    });

    test('ShiftModel correctly parses audit modification fields', () {
      final json = {
        'id': 'shift-001',
        'shift_number': 5,
        'user_id': 'u123',
        'opened_at': '2026-09-24T08:00:00.000Z',
        'closed_at': '2026-09-24T16:00:00.000Z',
        'initial_cash': 500.0,
        'total_sales': 2500.0,
        'status': 'closed',
        'is_modified': true,
        'modification_history': [
          {'reason': 'Ajuste supervisor', 'at': '2026-09-24T17:00:00.000Z'}
        ]
      };

      final shift = ShiftModel.fromJson(json);

      expect(shift.shiftNumber, 5);
      expect(shift.isModified, isTrue);
      expect(shift.modificationHistory, isNotNull);
      expect(shift.modificationHistory!.length, 1);
    });

    test('ChargeModel gracefully handles optional shiftId field', () {
      final chargeWithoutShift = const ChargeModel(
        amount: 50.0,
        userId: 'u1',
        concept: 'Mesa 1',
        paymentMethod: 'efectivo',
      );

      final jsonWithoutShift = chargeWithoutShift.toSupabaseJson();
      expect(jsonWithoutShift.containsKey('shift_id'), isFalse);

      final chargeWithShift = const ChargeModel(
        amount: 50.0,
        userId: 'u1',
        concept: 'Mesa 1',
        paymentMethod: 'efectivo',
        shiftId: 'shift-123',
      );

      final jsonWithShift = chargeWithShift.toSupabaseJson();
      expect(jsonWithShift['shift_id'], 'shift-123');
    });
  });
}
