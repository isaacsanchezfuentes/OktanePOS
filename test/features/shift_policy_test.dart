import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/cash_cut/services/shift_policy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShiftPolicyService Unit Tests', () {
    test('Evaluates canOpenNewShiftToday according to policy modes', () async {
      final service = ShiftPolicyService();

      // Mode 1: 1 turn per day
      expect(await service.canOpenNewShiftToday(0), isTrue);
      expect(await service.canOpenNewShiftToday(1), isFalse);

      // Mode descriptions
      expect(service.getModeDescription(1), contains('Modo 1'));
      expect(service.getModeDescription(2), contains('Modo 2'));
      expect(service.getModeDescription(3), contains('Modo 3'));
    });
  });
}
