import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/charge_model.dart';

class ChargeService {
  final SupabaseClient _client;

  ChargeService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  /// Creates a new pending charge record in Supabase 'charges' table.
  Future<ChargeModel> createPendingCharge({
    required double amount,
    required String userId,
    required String concept,
    required String paymentMethod,
    String currency = 'MXN',
  }) async {
    String? activeShiftId;
    try {
      final activeShift = await _client
          .from('shifts')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'open')
          .order('opened_at', ascending: false)
          .maybeSingle();

      if (activeShift != null) {
        activeShiftId = activeShift['id']?.toString();
      }
    } catch (e) {
      debugPrint('⚠️ Búsqueda opcional de shift_id omitida o nula: $e');
    }

    final charge = ChargeModel(
      amount: amount,
      currency: currency,
      status: 'pending',
      userId: userId,
      concept: concept,
      paymentMethod: paymentMethod,
      shiftId: activeShiftId,
      createdAt: DateTime.now(),
    );

    try {
      debugPrint('📡 Guardando cobro pendiente en Supabase: ${charge.toSupabaseJson()}');
      
      final response = await _client
          .from('charges')
          .insert(charge.toSupabaseJson())
          .select()
          .single();

      debugPrint('✅ Cobro guardado exitosamente: $response');
      return ChargeModel.fromJson(response);
    } catch (e, stack) {
      debugPrint('❌ Error creando registro en tabla charges: $e\n$stack');
      rethrow;
    }
  }

  /// Returns a real-time Stream of charges for the specified user (and optional shiftId), ordered by created_at descending.
  Stream<List<ChargeModel>> getTodayChargesStream(String userId, {String? shiftId}) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    try {
      if (shiftId != null && shiftId.isNotEmpty) {
        return _client
            .from('charges')
            .stream(primaryKey: ['id'])
            .eq('shift_id', shiftId)
            .order('created_at', ascending: false)
            .map((dataList) => dataList.map((json) => ChargeModel.fromJson(json)).toList());
      } else {
        return _client
            .from('charges')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .map((dataList) => dataList.map((json) => ChargeModel.fromJson(json)).toList());
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo stream de cobros: $e');
      return Stream.value([]);
    }
  }

  /// Updates the status of a charge record ('pending', 'paid', 'cancelled').
  Future<void> updateChargeStatus(String chargeId, String newStatus) async {
    try {
      final nowStr = DateTime.now().toIso8601String();
      debugPrint('📡 Actualizando estado del cobro $chargeId a $newStatus');
      await _client
          .from('charges')
          .update({'status': newStatus, 'updated_at': nowStr})
          .eq('id', chargeId);
      debugPrint('✅ Estado actualizado exitosamente');
    } catch (e, stack) {
      debugPrint('❌ Error actualizando estado del cobro $chargeId: $e\n$stack');
      rethrow;
    }
  }
}
