import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../../charge/services/charge_service.dart';
import '../../charge/models/charge_model.dart';

class TableService extends ChangeNotifier {
  final List<ZoneModel> _zones = const [
    ZoneModel(id: '11111111-1111-4000-8000-000000000001', name: 'Salón Principal', sortOrder: 1),
    ZoneModel(id: '11111111-1111-4000-8000-000000000002', name: 'Terraza Exterior', sortOrder: 2),
    ZoneModel(id: '11111111-1111-4000-8000-000000000003', name: 'Barra / Mostrador', sortOrder: 3),
  ];

  late final Map<String, List<RestaurantTableModel>> _tablesByZone;
  final Map<String, List<Map<String, dynamic>>> _tableDrafts = {};

  TableService() {
    _initDefaultTables();
  }

  static int _parseInt(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? defaultValue);
    }
    return defaultValue;
  }

  void saveTableDraft(String tableId, List<Map<String, dynamic>> items) {
    _tableDrafts[tableId] = List<Map<String, dynamic>>.from(items);
    debugPrint('📝 Borrador guardado localmente para Mesa $tableId: ${items.length} ítems');
    notifyListeners();
  }

  List<Map<String, dynamic>> getTableDraft(String tableId) {
    return List<Map<String, dynamic>>.from(_tableDrafts[tableId] ?? []);
  }

  void clearTableDraft(String tableId) {
    _tableDrafts.remove(tableId);
    debugPrint('🧹 Borrador limpiado para Mesa $tableId');
    notifyListeners();
  }

  void _initDefaultTables() {
    _tablesByZone = {
      '11111111-1111-4000-8000-000000000001': [
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000001', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 1, seats: 4, shape: 'square', posX: 0.20, posY: 0.25, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000002', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 2, seats: 4, shape: 'square', posX: 0.50, posY: 0.25, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000003', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 3, seats: 6, shape: 'circle', posX: 0.80, posY: 0.25, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000004', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 4, seats: 2, shape: 'square', posX: 0.20, posY: 0.65, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000005', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 5, seats: 8, shape: 'square', posX: 0.60, posY: 0.65, status: 'free'),
      ],
      '11111111-1111-4000-8000-000000000002': [
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000010', zoneId: '11111111-1111-4000-8000-000000000002', tableNumber: 10, seats: 4, shape: 'circle', posX: 0.30, posY: 0.30, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000011', zoneId: '11111111-1111-4000-8000-000000000002', tableNumber: 11, seats: 4, shape: 'circle', posX: 0.70, posY: 0.30, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000012', zoneId: '11111111-1111-4000-8000-000000000002', tableNumber: 12, seats: 6, shape: 'square', posX: 0.50, posY: 0.70, status: 'free'),
      ],
      '11111111-1111-4000-8000-000000000003': [
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000020', zoneId: '11111111-1111-4000-8000-000000000003', tableNumber: 20, seats: 1, shape: 'bar', posX: 0.25, posY: 0.40, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000021', zoneId: '11111111-1111-4000-8000-000000000003', tableNumber: 21, seats: 1, shape: 'bar', posX: 0.50, posY: 0.40, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000022', zoneId: '11111111-1111-4000-8000-000000000003', tableNumber: 22, seats: 1, shape: 'bar', posX: 0.75, posY: 0.40, status: 'free'),
      ],
    };
  }

  Future<void> fetchOrSeedSupabaseTables({SupabaseClient? client}) async {
    try {
      final supa = client ?? Supabase.instance.client;
      final List<dynamic> rows = await supa.from('restaurant_tables').select();

      if (rows.isNotEmpty) {
        debugPrint('📡 Supabase restaurant_tables cargadas: ${rows.length} mesas');
        for (final row in rows) {
          final id = row['id']?.toString();
          final zoneId = row['zone_id']?.toString() ?? '11111111-1111-4000-8000-000000000001';
          final number = _parseInt(row['table_number'], 1);
          final status = row['status']?.toString() ?? 'free';

          if (id != null) {
            final targetZoneKey = _tablesByZone.containsKey(zoneId) ? zoneId : _tablesByZone.keys.first;
            final list = _tablesByZone[targetZoneKey]!;
            final idx = list.indexWhere((t) => t.tableNumber == number || t.id == id);
            if (idx != -1) {
              final old = list[idx];
              list[idx] = RestaurantTableModel(
                id: id,
                zoneId: targetZoneKey,
                tableNumber: number,
                seats: old.seats,
                shape: old.shape,
                posX: old.posX,
                posY: old.posY,
                status: status,
                assignedWaiter: old.assignedWaiter,
                activeTickets: old.activeTickets,
              );
            }
          }
        }
        notifyListeners();
      } else {
        debugPrint('🌱 Iniciando seed de restaurant_tables en Supabase...');
        final List<Map<String, dynamic>> seedRows = [];
        for (final entry in _tablesByZone.entries) {
          for (final table in entry.value) {
            seedRows.add({
              'id': table.id,
              'zone_id': table.zoneId,
              'table_number': table.tableNumber,
              'status': 'free',
            });
          }
        }
        await supa.from('restaurant_tables').upsert(seedRows);
        debugPrint('✅ Seed de restaurant_tables completado exitosamente.');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Fetch/Seed opcional de restaurant_tables omitido o simulado: $e');
    }
  }

  List<ZoneModel> getZones() => List.unmodifiable(_zones);

  List<RestaurantTableModel> getTablesByZone(String zoneId) {
    return List.unmodifiable(_tablesByZone[zoneId] ?? []);
  }

  void updateTablePosition(String zoneId, String tableId, double posX, double posY) {
    final list = _tablesByZone[zoneId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        final table = list[index];
        list[index] = RestaurantTableModel(
          id: table.id,
          zoneId: table.zoneId,
          tableNumber: table.tableNumber,
          seats: table.seats,
          shape: table.shape,
          posX: posX.clamp(0.05, 0.90),
          posY: posY.clamp(0.05, 0.90),
          status: table.status,
          assignedWaiter: table.assignedWaiter,
          activeTickets: table.activeTickets,
        );
        debugPrint('📍 Posición actualizada para Mesa ${table.tableNumber}: posX=$posX, posY=$posY');
        notifyListeners();
      }
    }
  }

  Future<void> addTicketToTable(
    String zoneId,
    String tableId, {
    required double amount,
    required String concept,
    required String waiterId,
    required String waiterName,
    ChargeService? chargeService,
  }) async {
    final list = _tablesByZone[zoneId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        final table = list[index];
        final isPeerSupport = table.assignedWaiter != null && table.assignedWaiter != waiterName;
        final ticketId = 'tk-${DateTime.now().millisecondsSinceEpoch}';

        final newTicket = {
          'ticket_id': ticketId,
          'amount': amount,
          'concept': concept,
          'waiter_id': waiterId,
          'waiter_name': waiterName,
          'is_peer_support': isPeerSupport,
          'created_at': DateTime.now().toIso8601String(),
        };

        final updatedTickets = List<Map<String, dynamic>>.from(table.activeTickets)..add(newTicket);

        list[index] = RestaurantTableModel(
          id: table.id,
          zoneId: table.zoneId,
          tableNumber: table.tableNumber,
          seats: table.seats,
          shape: table.shape,
          posX: table.posX,
          posY: table.posY,
          status: 'occupied',
          assignedWaiter: table.assignedWaiter ?? waiterName,
          activeTickets: updatedTickets,
        );

        debugPrint('🎟️ Ticket agregado a Mesa ${table.tableNumber}. Es Apoyo: $isPeerSupport');
        notifyListeners();

        final String tableLabel = 'Mesa #${table.tableNumber}';

        // Create or update single unified pending charge record
        try {
          final cs = chargeService ?? ChargeService();
          await cs.createOrUpdatePendingChargeForTable(
            tableId: tableId,
            newRoundAmount: amount,
            userId: waiterId,
            roundConcept: concept,
            tableLabel: tableLabel,
          );
        } catch (e) {
          debugPrint('⚠️ Error al registrar charge unificado pendiente: $e');
        }
      }
    }
  }

  void removeTicketAndCheckFree(String zoneId, String tableId, String ticketId) {
    final list = _tablesByZone[zoneId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        final table = list[index];
        final updatedTickets = table.activeTickets.where((t) => t['ticket_id'] != ticketId).toList();

        final newStatus = updatedTickets.isEmpty ? 'free' : 'occupied';
        final newWaiter = updatedTickets.isEmpty ? null : table.assignedWaiter;

        list[index] = RestaurantTableModel(
          id: table.id,
          zoneId: table.zoneId,
          tableNumber: table.tableNumber,
          seats: table.seats,
          shape: table.shape,
          posX: table.posX,
          posY: table.posY,
          status: newStatus,
          assignedWaiter: newWaiter,
          activeTickets: updatedTickets,
        );

        debugPrint('✅ Ticket $ticketId removido de Mesa ${table.tableNumber}. Nuevo estatus: $newStatus');
        notifyListeners();
      }
    }
  }

  void clearAllTableTickets(String zoneId, String tableId) {
    final list = _tablesByZone[zoneId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        final table = list[index];
        list[index] = RestaurantTableModel(
          id: table.id,
          zoneId: table.zoneId,
          tableNumber: table.tableNumber,
          seats: table.seats,
          shape: table.shape,
          posX: table.posX,
          posY: table.posY,
          status: 'free',
          assignedWaiter: null,
          activeTickets: const [],
        );
        debugPrint('🧹 Mesa ${table.tableNumber} totalmente liberada (estatus: free).');
        notifyListeners();
      }
    }
  }
}
