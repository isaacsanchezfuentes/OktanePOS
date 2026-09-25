import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ShiftPolicyService {
  final FlutterSecureStorage _storage;

  static const String _keyPolicyMode = 'shift_policy_mode';

  ShiftPolicyService({FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage();

  /// Gets the current shift policy mode (1 = 1 per day, 2 = 3 per day, 3 = manual/free).
  Future<int> getPolicyMode() async {
    try {
      final value = await _storage.read(key: _keyPolicyMode);
      if (value != null) {
        final parsed = int.tryParse(value);
        if (parsed != null && (parsed >= 1 && parsed <= 3)) {
          return parsed;
        }
      }
      return 1; // Default: Mode 1 (1 shift per day)
    } catch (e) {
      debugPrint('⚠️ Error leyendo política de turnos: $e');
      return 1;
    }
  }

  /// Sets the shift policy mode.
  Future<void> setPolicyMode(int mode) async {
    try {
      await _storage.write(key: _keyPolicyMode, value: mode.toString());
      debugPrint('✅ Política de turnos actualizada a Modo $mode');
    } catch (e) {
      debugPrint('❌ Error guardando política de turnos: $e');
    }
  }

  /// Checks if a new shift can be opened today based on current mode and number of shifts closed today.
  Future<bool> canOpenNewShiftToday(int closedTodayCount) async {
    final mode = await getPolicyMode();
    switch (mode) {
      case 1:
        return closedTodayCount < 1;
      case 2:
        return closedTodayCount < 3;
      case 3:
      default:
        return true;
    }
  }

  /// Returns user-friendly description of policy mode.
  String getModeDescription(int mode) {
    switch (mode) {
      case 1:
        return 'Modo 1: Máximo 1 turno por día (Default)';
      case 2:
        return 'Modo 2: Hasta 3 turnos por día';
      case 3:
      default:
        return 'Modo 3: Turnos libres / manuales por rango de horas';
    }
  }
}
