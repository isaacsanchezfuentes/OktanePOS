import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cash_cut_model.dart';

class CashCutService {
  final SupabaseClient _client;

  CashCutService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  /// Queries all charges for today or for a specific active shift and returns a consolidated summary.
  Future<CashCutSummaryModel> getTodaySummary(String userId, {String? shiftId}) async {
    if (userId.isEmpty) {
      return CashCutSummaryModel(
        totalCollected: 0.0,
        totalCash: 0.0,
        totalCard: 0.0,
        totalQr: 0.0,
        totalTransactions: 0,
        pendingTransactions: 0,
        averageTicket: 0.0,
        userId: userId,
      );
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

      List<dynamic> response;
      if (shiftId != null && shiftId.isNotEmpty) {
        debugPrint('📡 Obteniendo resumen de corte por shift_id $shiftId');
        response = await _client
            .from('charges')
            .select()
            .eq('shift_id', shiftId);
      } else {
        debugPrint('📡 Obteniendo resumen de corte por fecha desde $startOfDay');
        response = await _client
            .from('charges')
            .select()
            .eq('user_id', userId)
            .gte('created_at', startOfDay);
      }

      return CashCutSummaryModel.fromCharges(response, userId);
    } catch (e, stack) {
      debugPrint('❌ Error obteniendo datos para corte de caja: $e\n$stack');
      rethrow;
    }
  }
}
