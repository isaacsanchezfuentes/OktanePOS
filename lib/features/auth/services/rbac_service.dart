import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PosRole { waiter, manager, admin }

class RbacService {
  final FlutterSecureStorage _storage;

  static const String _keyManagerPin = 'manager_pin';
  static const String _keyWaiterPin = 'waiter_pin';

  RbacService({FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage();

  PosRole parseRole(String? rawRole) {
    if (rawRole == null) return PosRole.waiter;
    final normalized = rawRole.toUpperCase();
    if (normalized.contains('ADMIN')) return PosRole.admin;
    if (normalized.contains('GERENTE') || normalized.contains('MANAGER')) return PosRole.manager;
    return PosRole.waiter; // CHOFER / MESERO / WAITER
  }

  bool isWaiter(String? rawRole) {
    return parseRole(rawRole) == PosRole.waiter;
  }

  bool isManagerOrAdmin(String? rawRole) {
    final role = parseRole(rawRole);
    return role == PosRole.manager || role == PosRole.admin;
  }

  Future<bool> verifyManagerPin(String inputPin) async {
    try {
      final savedPin = await _storage.read(key: _keyManagerPin);
      final validPin = savedPin ?? '1234'; // Default manager PIN
      return inputPin.trim() == validPin;
    } catch (e) {
      debugPrint('⚠️ Error verificando PIN de Gerente: $e');
      return inputPin.trim() == '1234';
    }
  }

  Future<bool> verifyWaiterPin(String inputPin) async {
    try {
      final savedPin = await _storage.read(key: _keyWaiterPin);
      final validPin = savedPin ?? '0000'; // Default waiter PIN
      return inputPin.trim() == validPin;
    } catch (e) {
      debugPrint('⚠️ Error verificando PIN de Mesero: $e');
      return inputPin.trim() == '0000';
    }
  }

  Future<void> logPrintAuditOverride({
    required String waiterId,
    required String reason,
    required double amount,
  }) async {
    debugPrint('🚨 [AUDITORÍA EXCEPCIÓN IMPRESIÓN] Mesero: $waiterId | Motivo: $reason | Monto: \$$amount MXN | Timestamp: ${DateTime.now()}');
  }
}
