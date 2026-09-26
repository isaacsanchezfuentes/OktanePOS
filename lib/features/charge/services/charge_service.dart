import 'dart:async';
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

    String? validTableId;
    if (tableId != null && tableId.isNotEmpty && _uuidRegExp.hasMatch(tableId)) {
      validTableId = tableId;
    }

    String? validWaiterId;
    if (waiterId != null && waiterId.isNotEmpty && _uuidRegExp.hasMatch(waiterId) && waiterId != activeAuthUserId) {
      validWaiterId = waiterId;
    }

    final newCharge = ChargeModel(
      amount: amount,
      currency: currency,
      userId: activeAuthUserId,
      status: 'pending',
      concept: concept,
      paymentMethod: paymentMethod,
      tableId: validTableId,
      waiterId: validWaiterId,
      createdAt: DateTime.now(),
    );

    try {
      final payload = newCharge.toSupabaseJson();
      final response = await _client
          .from('charges')
          .insert(payload)
          .select()
          .single();

      debugPrint('✅ Charge creado exitosamente con ID ${response['id']}');
      return ChargeModel.fromJson(response);
    } catch (e, stack) {
      debugPrint('❌ Error creando registro en tabla charges: $e\n$stack');
      rethrow;
    }
  }

  /// Direct REST GET query for historical charges, ordered by created_at descending.
  Future<List<ChargeModel>> getTodayChargesRest(String userId, {String? shiftId}) async {
    if (userId.isEmpty) return [];

    try {
      final List<dynamic> response;
      if (shiftId != null && shiftId.isNotEmpty) {
        response = await _client
            .from('charges')
            .select()
            .eq('shift_id', shiftId)
            .order('created_at', ascending: false);
      } else {
        response = await _client
            .from('charges')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      }

      return response.map((json) => ChargeModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Error obteniendo cobros vía REST GET: $e');
      return [];
    }
  }

  /// Returns a resilient hybrid Stream of charges for the specified user (and optional shiftId).
  /// Performs an initial REST GET fetch followed by an optional Realtime channel subscription.
  Stream<List<ChargeModel>> getTodayChargesStream(String userId, {String? shiftId}) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    late final StreamController<List<ChargeModel>> controller;
    RealtimeChannel? realtimeChannel;

    controller = StreamController<List<ChargeModel>>.broadcast(
      onListen: () async {
        // 1. Initial REST GET fetch
        try {
          final initialData = await getTodayChargesRest(userId, shiftId: shiftId);
          if (!controller.isClosed) {
            controller.add(initialData);
          }
        } catch (e) {
          debugPrint('⚠️ Initial REST GET fetch error: $e');
        }

        // 2. Resilient Realtime Channel Subscription
        try {
          final channelName = 'public:charges:${userId.isEmpty ? 'anon' : userId}';
          realtimeChannel = _client.channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'charges',
              callback: (payload) async {
                try {
                  final updatedList = await getTodayChargesRest(userId, shiftId: shiftId);
                  if (!controller.isClosed) {
                    controller.add(updatedList);
                  }
                } catch (e) {
                  debugPrint('⚠️ Error re-consultando cobros tras cambio Realtime: $e');
                }
              },
            )
            .subscribe((status, [error]) {
              if (status == RealtimeSubscribeStatus.channelError) {
                debugPrint('ℹ️ Aviso: Realtime no disponible (channelError), operando en modo HTTP normal');
              }
            });
        } catch (e) {
          debugPrint('ℹ️ Excepción en suscripción Realtime capturada, operando en modo HTTP normal: $e');
        }
      },
      onCancel: () {
        if (realtimeChannel != null) {
          try {
            _client.removeChannel(realtimeChannel!);
          } catch (_) {}
        }
      },
    );

    return controller.stream;
  }

  /// Updates the status of a charge record ('pending', 'paid', 'cancelled').
  Future<void> updateChargeStatus(String chargeId, String newStatus) async {
    return updateChargeStatusAndMethod(chargeId, newStatus);
  }

  /// Updates the status and payment method of a charge record ('pending', 'paid', 'cancelled').
  Future<void> updateChargeStatusAndMethod(String chargeId, String newStatus, {String? paymentMethod}) async {
    final Map<String, dynamic> updates = {
      'status': newStatus,
    };
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      updates['payment_method'] = paymentMethod;
    }

    try {
      await _client
          .from('charges')
          .update(updates)
          .eq('id', chargeId);

      debugPrint('✅ Estatus de charge $chargeId actualizado a $newStatus (método: $paymentMethod)');

      // If status updated to paid or cancelled, check if linked to a table
      if (newStatus == 'paid' || newStatus == 'cancelled') {
        try {
          final chargeRow = await _client.from('charges').select('table_id').eq('id', chargeId).maybeSingle();
          if (chargeRow != null && chargeRow['table_id'] != null) {
            final String tableId = chargeRow['table_id'].toString();

            final pendingCountResponse = await _client
                .from('charges')
                .select('id')
                .eq('table_id', tableId)
                .eq('status', 'pending');

            final int pendingCount = (pendingCountResponse as List).length;

            if (pendingCount == 0) {
              await _client
                  .from('restaurant_tables')
                  .update({'status': 'free'})
                  .eq('id', tableId);
              debugPrint('🧹 Mesa $tableId liberada en Supabase (0 cargos pendientes restantes)');
            } else {
              debugPrint('ℹ️ Mesa $tableId permanece ocupada ($pendingCount cargos pendientes)');
            }
          }
        } catch (tableErr) {
          debugPrint('⚠️ Error verificando/actualizando estatus de mesa en Supabase: $tableErr');
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Error actualizando estatus de charge $chargeId: $e\n$stack');
      rethrow;
    }
  }

  /// Creates a single unified pending charge record or updates an existing pending charge for a table.
  Future<ChargeModel> createOrUpdatePendingChargeForTable({
    required String tableId,
    required double newRoundAmount,
    required String userId,
    required String roundConcept,
    required String tableLabel,
  }) async {
    final String activeAuthUserId = _client.auth.currentUser?.id ?? userId;

    String? validTableId;
    if (_uuidRegExp.hasMatch(tableId)) {
      validTableId = tableId;
    }

    try {
      // 1. Query existing pending charge for this table
      final existingResponse = await _client
          .from('charges')
          .select()
          .eq('table_id', validTableId ?? tableId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingResponse != null) {
        final currentAmount = (existingResponse['amount'] as num?)?.toDouble() ?? 0.0;
        final currentConcept = existingResponse['concept']?.toString() ?? '';
        final currentChargeId = existingResponse['id']?.toString() ?? '';

        final totalUpdatedAmount = currentAmount + newRoundAmount;
        final updatedConcept = currentConcept.isNotEmpty
            ? '$currentConcept | $roundConcept'
            : roundConcept;

        final updatePayload = {
          'amount': totalUpdatedAmount,
          'concept': updatedConcept,
        };

        final updatedRow = await _client
            .from('charges')
            .update(updatePayload)
            .eq('id', currentChargeId)
            .select()
            .single();

        debugPrint('🔄 Charge unificado actualizado para Mesa $tableLabel: Total \$${totalUpdatedAmount.toStringAsFixed(2)}');

        // Update table status to occupied in Supabase
        if (validTableId != null) {
          await _client.from('restaurant_tables').update({'status': 'occupied'}).eq('id', validTableId);
        }

        return ChargeModel.fromJson(updatedRow);
      } else {
        // 2. Create new single pending charge
        final newCharge = ChargeModel(
          amount: newRoundAmount,
          currency: 'MXN',
          userId: activeAuthUserId,
          status: 'pending',
          concept: roundConcept,
          paymentMethod: 'cash',
          tableId: validTableId,
          createdAt: DateTime.now(),
        );

        final payload = newCharge.toSupabaseJson();
        final createdRow = await _client
            .from('charges')
            .insert(payload)
            .select()
            .single();

        debugPrint('✨ Nuevo Charge unificado creado para Mesa $tableLabel: \$${newRoundAmount.toStringAsFixed(2)}');

        // Update table status to occupied in Supabase
        if (validTableId != null) {
          await _client.from('restaurant_tables').update({'status': 'occupied'}).eq('id', validTableId);
        }

        return ChargeModel.fromJson(createdRow);
      }
    } catch (e, stack) {
      debugPrint('❌ Error creando/actualizando charge unificado de mesa: $e\n$stack');
      rethrow;
    }
  }
}
