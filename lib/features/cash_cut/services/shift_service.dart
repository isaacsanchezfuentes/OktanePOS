import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_model.dart';
import '../models/cash_cut_model.dart';

class ShiftService {
  final SupabaseClient _client;

  ShiftService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  /// Retrieves the current open shift for the user, if any.
  Future<ShiftModel?> getActiveShift(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final response = await _client
          .from('shifts')
          .select()
          .eq('user_id', userId)
          .eq('status', 'open')
          .order('opened_at', ascending: false)
          .maybeSingle();

      if (response != null) {
        return ShiftModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error buscando turno activo para $userId: $e');
      return null;
    }
  }

  /// Retrieves all closed shifts for the user ordered by closed_at descending.
  Future<List<ShiftModel>> getClosedShifts(String userId) async {
    if (userId.isEmpty) return [];

    try {
      final List<dynamic> response = await _client
          .from('shifts')
          .select()
          .eq('user_id', userId)
          .eq('status', 'closed')
          .order('closed_at', ascending: false);

      return response.map((json) => ShiftModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Error obteniendo historial de turnos cerrados: $e');
      return [];
    }
  }

  /// Opens a new shift in Supabase 'shifts' table.
  Future<ShiftModel> openShift({
    required String userId,
    double initialCash = 0.0,
  }) async {
    final newShift = ShiftModel(
      userId: userId,
      openedAt: DateTime.now(),
      initialCash: initialCash,
      status: 'open',
    );

    try {
      debugPrint('📡 Abriendo nuevo turno en Supabase: ${newShift.toSupabaseInsertJson()}');

      final response = await _client
          .from('shifts')
          .insert(newShift.toSupabaseInsertJson())
          .select()
          .single();

      debugPrint('✅ Turno abierto exitosamente: $response');
      return ShiftModel.fromJson(response);
    } catch (e, stack) {
      debugPrint('❌ Error abriendo nuevo turno: $e\n$stack');
      rethrow;
    }
  }

  /// Closes an existing open shift in Supabase 'shifts' table.
  Future<ShiftModel> closeShift({
    required String shiftId,
    required CashCutSummaryModel summary,
    required double initialCash,
    required double countedCash,
    required double difference,
  }) async {
    final closeData = {
      'closed_at': DateTime.now().toIso8601String(),
      'total_sales': summary.totalCollected,
      'cash_sales': summary.totalCash,
      'card_sales': summary.totalCard,
      'qr_sales': summary.totalQr,
      'drawer_counted': countedCash,
      'difference': difference,
      'status': 'closed',
    };

    try {
      debugPrint('📡 Cerrando turno $shiftId en Supabase: $closeData');

      final response = await _client
          .from('shifts')
          .update(closeData)
          .eq('id', shiftId)
          .select()
          .single();

      debugPrint('✅ Turno cerrado exitosamente en Supabase: $response');
      return ShiftModel.fromJson(response);
    } catch (e, stack) {
      debugPrint('❌ Error cerrando turno $shiftId: $e\n$stack');
      rethrow;
    }
  }
}
