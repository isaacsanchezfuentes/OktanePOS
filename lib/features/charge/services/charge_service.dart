import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/charge_model.dart';

class ChargeService {
  final SupabaseClient _client;

  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  ChargeService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  /// Creates a new pending charge record in Supabase 'charges' table.
  Future<ChargeModel> createPendingCharge({
    required double amount,
    required String userId,
    required String concept,
    required String paymentMethod,
    String? tableId,
    String? waiterId,
    String currency = 'MXN',
  }) async {
    final String activeAuthUserId = _client.auth.currentUser?.id ?? userId;

    String? activeShiftId;
    try {
      final activeShift = await _client
          .from('shifts')
          .select('id')
          .eq('user_id', activeAuthUserId)
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
      userId: activeAuthUserId,
      concept: concept,
      paymentMethod: paymentMethod,
      shiftId: activeShiftId,
      tableId: tableId,
      waiterId: (waiterId != null && waiterId != activeAuthUserId) ? waiterId : null,
      createdAt: DateTime.now(),
    );

    try {
      debugPrint('📡 Guardando cobro pendiente en Supabase con table_id=$tableId & waiter_id=${charge.waiterId}: ${charge.toSupabaseJson()}');
      
      final response = await _client
          .from('charges')
          .insert(charge.toSupabaseJson())
          .select()
          .single();

      // Update Supabase restaurant_tables status if valid tableId exists
      if (tableId != null && _uuidRegExp.hasMatch(tableId)) {
        try {
          await _client
              .from('restaurant_tables')
              .update({'status': 'occupied'})
              .eq('id', tableId);
          debugPrint('✅ Estado de mesa $tableId actualizado a occupied en Supabase');
        } catch (e) {
          debugPrint('⚠️ Actualización opcional de mesa en Supabase omitida: $e');
        }
      }

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
    return updateChargeStatusAndMethod(chargeId, newStatus);
  }

  /// Updates the status and payment method of a charge record ('pending', 'paid', 'cancelled').
  Future<void> updateChargeStatusAndMethod(String chargeId, String newStatus, {String? paymentMethod, String? tableId}) async {
    try {
      final nowStr = DateTime.now().toIso8601String();
      final Map<String, dynamic> updates = {
        'status': newStatus,
        'updated_at': nowStr,
      };
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        updates['payment_method'] = paymentMethod;
      }
      debugPrint('📡 Actualizando estado del cobro $chargeId a $newStatus (método: $paymentMethod)');
      await _client
          .from('charges')
          .update(updates)
          .eq('id', chargeId);

      // If status is paid, liberate table in Supabase
      if (newStatus == 'paid') {
        try {
          String? targetTableId = tableId;
          if (targetTableId == null || targetTableId.isEmpty) {
            final chargeRow = await _client.from('charges').select('table_id').eq('id', chargeId).maybeSingle();
            if (chargeRow != null) {
              targetTableId = chargeRow['table_id']?.toString();
            }
          }

          if (targetTableId != null && _uuidRegExp.hasMatch(targetTableId)) {
            await _client.from('restaurant_tables').update({'status': 'available'}).eq('id', targetTableId);
            debugPrint('🧹 Mesa $targetTableId liberada (status = available) en Supabase');
          }
        } catch (e) {
          debugPrint('⚠️ Liberación de mesa en Supabase omitida o simulada: $e');
        }
      }

      debugPrint('✅ Estado actualizado exitosamente');
    } catch (e, stack) {
      debugPrint('❌ Error actualizando estado del cobro $chargeId: $e\n$stack');
      rethrow;
    }
  }

  /// Creates or updates a unified pending charge record for a table, strictly accumulating new round amount to existing pending amount.
  Future<ChargeModel> createOrUpdatePendingChargeForTable({
    required String tableId,
    required double newRoundAmount,
    required String userId,
    required String roundConcept,
    required String tableLabel,
    String? waiterId,
  }) async {
    final String activeAuthUserId = _client.auth.currentUser?.id ?? userId;

    try {
      final String matchPrefix = '$tableLabel -';
      final existing = await _client
          .from('charges')
          .select()
          .eq('status', 'pending')
          .or('table_id.eq.$tableId,concept.ilike.$matchPrefix%')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        final existingId = existing['id'].toString();
        final double currentAmount = (existing['amount'] as num).toDouble();
        final double totalUpdatedAmount = currentAmount + newRoundAmount;
        final String existingConcept = existing['concept']?.toString() ?? '$tableLabel - Consumo';
        final String updatedConcept = '$existingConcept + $roundConcept';

        debugPrint('📡 Acumulando orden unificada $existingId (Mesa: $tableId): \$${currentAmount.toStringAsFixed(2)} + \$${newRoundAmount.toStringAsFixed(2)} = \$${totalUpdatedAmount.toStringAsFixed(2)}');

        final Map<String, dynamic> updateData = {
          'amount': totalUpdatedAmount,
          'concept': updatedConcept,
          'user_id': activeAuthUserId,
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (_uuidRegExp.hasMatch(tableId)) {
          updateData['table_id'] = tableId;
        }

        if (waiterId != null && waiterId != activeAuthUserId && _uuidRegExp.hasMatch(waiterId)) {
          updateData['waiter_id'] = waiterId;
        }

        await _client
            .from('charges')
            .update(updateData)
            .eq('id', existingId);

        // Update Supabase restaurant_tables status
        if (_uuidRegExp.hasMatch(tableId)) {
          try {
            await _client
                .from('restaurant_tables')
                .update({'status': 'occupied'})
                .eq('id', tableId);
            debugPrint('✅ Estado de mesa $tableId actualizado a occupied en Supabase');
          } catch (e) {
            debugPrint('⚠️ Actualización opcional de mesa en Supabase omitida: $e');
          }
        }

        final updated = await _client
            .from('charges')
            .select()
            .eq('id', existingId)
            .single();

        return ChargeModel.fromJson(updated);
      }
    } catch (e) {
      debugPrint('⚠️ Búsqueda de orden pendiente unificada para $tableLabel omitida: $e');
    }

    final initialConcept = '$tableLabel - $roundConcept';
    return createPendingCharge(
      amount: newRoundAmount,
      userId: activeAuthUserId,
      concept: initialConcept,
      paymentMethod: 'efectivo',
      tableId: tableId,
      waiterId: waiterId,
    );
  }
}
