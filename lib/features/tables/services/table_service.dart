import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../../charge/services/charge_service.dart';

class TableService extends ChangeNotifier {
  static final TableService _instance = TableService._internal();

  factory TableService({SupabaseClient? client}) => _instance;

  TableService._internal() {
    _initDefaultTables();
  }

  final List<ZoneModel> _zones = const [
    ZoneModel(id: '11111111-1111-4000-8000-000000000001', name: 'Salón Principal', sortOrder: 1),
    ZoneModel(id: '11111111-1111-4000-8000-000000000002', name: 'Terraza Exterior', sortOrder: 2),
    ZoneModel(id: '11111111-1111-4000-8000-000000000003', name: 'Para Llevar', sortOrder: 3),
  ];

  late final Map<String, List<RestaurantTableModel>> _tablesByZone;
  final Map<String, List<Map<String, dynamic>>> _tableDrafts = {};

  void notifyTableUpdate() {
    notifyListeners();
  }

  static int _parseInt(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? defaultValue);
    }
    return defaultValue;
  }

  static double _parseDouble(dynamic val, double defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? defaultValue;
    }
    return defaultValue;
  }

  static bool _parseBool(dynamic val, bool defaultValue) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val == 1;
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 't') return true;
      if (s == 'false' || s == '0' || s == 'f') return false;
    }
    return defaultValue;
  }

  void saveTableDraft(String tableId, List<Map<String, dynamic>> items) {
    _tableDrafts[tableId] = List<Map<String, dynamic>>.from(items);
    notifyListeners();
  }

  List<Map<String, dynamic>> getTableDraft(String tableId) {
    return List<Map<String, dynamic>>.from(_tableDrafts[tableId] ?? []);
  }

  void clearTableDraft(String tableId) {
    _tableDrafts.remove(tableId);
    notifyListeners();
  }

  void _initDefaultTables() {
    _tablesByZone = {
      '11111111-1111-4000-8000-000000000001': [
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000001', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 1, label: 'Mesa 1', seats: 4, shape: 'square', posX: 0.12, posY: 0.15, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000002', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 2, label: 'Mesa 2', seats: 4, shape: 'square', posX: 0.58, posY: 0.15, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000003', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 3, label: 'Mesa 3', seats: 6, shape: 'round', posX: 0.12, posY: 0.55, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000004', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 4, label: 'Mesa 4', seats: 2, shape: 'square', posX: 0.58, posY: 0.55, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000005', zoneId: '11111111-1111-4000-8000-000000000001', tableNumber: 5, label: 'Mesa 5', seats: 8, shape: 'square', posX: 0.35, posY: 0.35, status: 'free'),
      ],
      '11111111-1111-4000-8000-000000000002': [
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000010', zoneId: '11111111-1111-4000-8000-000000000002', tableNumber: 10, label: 'Mesa 10', seats: 4, shape: 'round', posX: 0.20, posY: 0.25, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000011', zoneId: '11111111-1111-4000-8000-000000000002', tableNumber: 11, label: 'Mesa 11', seats: 4, shape: 'round', posX: 0.65, posY: 0.25, status: 'free'),
        const RestaurantTableModel(id: '00000000-0000-4000-8000-000000000012', zoneId: '11111111-1111-4000-8000-000000000002', tableNumber: 12, label: 'Mesa 12', seats: 6, shape: 'square', posX: 0.42, posY: 0.65, status: 'free'),
      ],
      '11111111-1111-4000-8000-000000000003': [
        const RestaurantTableModel(
          id: '00000000-0000-4000-8000-000000000019',
          zoneId: '11111111-1111-4000-8000-000000000003',
          tableNumber: 0,
          label: 'BARRA PRINCIPAL',
          seats: 0,
          shape: 'counter',
          posX: 0.12,
          posY: 0.20,
          width: 0.65,
          height: 0.12,
          status: 'free',
          isStructural: true,
        ),
        const RestaurantTableModel(
          id: '00000000-0000-4000-8000-000000000020',
          zoneId: '11111111-1111-4000-8000-000000000003',
          tableNumber: 1,
          label: 'Banquillo 1',
          seats: 1,
          shape: 'stool',
          posX: 0.18,
          posY: 0.50,
          status: 'free',
        ),
        const RestaurantTableModel(
          id: '00000000-0000-4000-8000-000000000021',
          zoneId: '11111111-1111-4000-8000-000000000003',
          tableNumber: 2,
          label: 'Banquillo 2',
          seats: 1,
          shape: 'stool',
          posX: 0.45,
          posY: 0.50,
          status: 'free',
        ),
        const RestaurantTableModel(
          id: '00000000-0000-4000-8000-000000000022',
          zoneId: '11111111-1111-4000-8000-000000000003',
          tableNumber: 3,
          label: 'Banquillo 3',
          seats: 1,
          shape: 'stool',
          posX: 0.72,
          posY: 0.50,
          status: 'free',
        ),
      ],
    };
  }

  Future<void> fetchOrSeedSupabaseTables({SupabaseClient? client}) async {
    try {
      final supa = client ?? Supabase.instance.client;
      final List<dynamic> rows = await supa.from('restaurant_tables').select();

      if (rows.isNotEmpty) {
        for (final row in rows) {
          final id = row['id']?.toString();
          final zoneId = row['zone_id']?.toString() ?? '11111111-1111-4000-8000-000000000001';
          int number = _parseInt(row['table_number'], 1);
          final shape = row['shape']?.toString() ?? 'square';
          final isStructural = _parseBool(row['is_structural'], false);

          if (id != null) {
            final targetZoneKey = _tablesByZone.containsKey(zoneId) ? zoneId : _tablesByZone.keys.first;
            final list = _tablesByZone[targetZoneKey]!;
            
            int idx = list.indexWhere((t) => t.id == id);
            if (idx == -1) {
              idx = list.indexWhere((t) => t.tableNumber == number && t.isStructural == isStructural);
            }

            String? rawLabel = row['label']?.toString();
            if (shape == 'stool') {
              if (number == 20) number = 1;
              if (number == 21) number = 2;
              if (number == 22) number = 3;
              if (rawLabel == null || rawLabel.isEmpty || rawLabel.startsWith('B') || rawLabel.contains('20')) {
                rawLabel = 'Banquillo $number';
              }
            }

            final parsedTable = RestaurantTableModel(
              id: id,
              zoneId: targetZoneKey,
              tableNumber: number,
              label: rawLabel ?? (idx != -1 ? list[idx].label : (shape == 'stool' ? 'Banquillo $number' : 'Mesa $number')),
              seats: _parseInt(row['seats'], shape == 'stool' ? 1 : 4),
              shape: shape,
              posX: _parseDouble(row['pos_x'], 0.2),
              posY: _parseDouble(row['pos_y'], 0.2),
              width: _parseDouble(row['width'], 0.14),
              height: _parseDouble(row['height'], 0.10),
              status: row['status']?.toString() ?? 'free',
              isStructural: isStructural,
              assignedWaiter: row['assigned_waiter']?.toString(),
              activeTickets: idx != -1 ? list[idx].activeTickets : [],
            );

            if (idx != -1) {
              list[idx] = parsedTable;
            } else {
              list.add(parsedTable);
            }
          }
        }

        // Algoritmo anti-colisión para separar mesas superpuestas
        for (final entry in _tablesByZone.entries) {
          final list = entry.value;
          for (int i = 0; i < list.length; i++) {
            for (int j = i + 1; j < list.length; j++) {
              if ((list[i].posX - list[j].posX).abs() < 0.08 && (list[i].posY - list[j].posY).abs() < 0.08) {
                list[j] = list[j].copyWith(
                  posX: (list[i].posX + 0.38).clamp(0.05, 0.85),
                );
              }
            }
          }
        }

        notifyListeners();
      } else {
        final List<Map<String, dynamic>> seedRows = [];
        for (final entry in _tablesByZone.entries) {
          for (final table in entry.value) {
            seedRows.add({
              'id': table.id,
              'zone_id': table.zoneId,
              'table_number': table.tableNumber,
              'label': table.label,
              'seats': table.seats,
              'shape': table.shape,
              'pos_x': table.posX,
              'pos_y': table.posY,
              'width': table.width,
              'height': table.height,
              'is_structural': table.isStructural,
              'status': 'free',
            });
          }
        }
        await supa.from('restaurant_tables').upsert(seedRows);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ℹ️ Supabase tables fetch/seed offline mode: $e');
    }
  }

  List<ZoneModel> getZones() => List.unmodifiable(_zones);

  List<RestaurantTableModel> getTablesByZone(String zoneId) {
    return List.unmodifiable(_tablesByZone[zoneId] ?? []);
  }

  Future<void> addTable(RestaurantTableModel newTable) async {
    final zoneKey = _tablesByZone.containsKey(newTable.zoneId)
        ? newTable.zoneId
        : _tablesByZone.keys.first;

    _tablesByZone.putIfAbsent(zoneKey, () => []).add(newTable);
    notifyListeners();

    try {
      await Supabase.instance.client.from('restaurant_tables').upsert({
        'id': newTable.id,
        'zone_id': newTable.zoneId,
        'table_number': newTable.tableNumber,
        'label': newTable.label,
        'seats': newTable.seats,
        'shape': newTable.shape,
        'pos_x': newTable.posX,
        'pos_y': newTable.posY,
        'width': newTable.width,
        'height': newTable.height,
        'is_structural': newTable.isStructural,
        'status': newTable.status,
      });
    } catch (e) {
      debugPrint('⚠️ Error agregando elemento a Supabase: $e');
    }
  }

  Future<bool> deleteTable(String zoneId, String tableId) async {
    String? foundZoneKey;
    int index = -1;

    if (_tablesByZone.containsKey(zoneId)) {
      index = _tablesByZone[zoneId]!.indexWhere((t) => t.id == tableId);
      if (index != -1) foundZoneKey = zoneId;
    }

    if (foundZoneKey == null) {
      for (final entry in _tablesByZone.entries) {
        final idx = entry.value.indexWhere((t) => t.id == tableId);
        if (idx != -1) {
          foundZoneKey = entry.key;
          index = idx;
          break;
        }
      }
    }

    if (foundZoneKey == null || index == -1) return false;

    if (_tablesByZone[foundZoneKey]![index].activeTickets.isNotEmpty) {
      return false;
    }

    _tablesByZone[foundZoneKey]!.removeAt(index);
    notifyListeners();

    try {
      await Supabase.instance.client.from('restaurant_tables').delete().eq('id', tableId);
    } catch (e) {
      debugPrint('⚠️ Error eliminando elemento de Supabase: $e');
    }
    return true;
  }

  Future<void> updateTableElement(RestaurantTableModel updated) async {
    for (final entry in _tablesByZone.entries) {
      final idx = entry.value.indexWhere((t) => t.id == updated.id);
      if (idx != -1) {
        entry.value[idx] = updated;
        notifyListeners();
        break;
      }
    }

    try {
      await Supabase.instance.client.from('restaurant_tables').upsert({
        'id': updated.id,
        'zone_id': updated.zoneId,
        'table_number': updated.tableNumber,
        'label': updated.label,
        'seats': updated.seats,
        'shape': updated.shape,
        'width': updated.width,
        'height': updated.height,
        'is_structural': updated.isStructural,
        'pos_x': updated.posX,
        'pos_y': updated.posY,
      });
    } catch (e) {
      debugPrint('⚠️ Error actualizando elemento en Supabase: $e');
    }
  }

  void updateTablePosition(String zoneId, String tableId, double posX, double posY) {
    String? targetZoneKey;
    int index = -1;

    if (_tablesByZone.containsKey(zoneId)) {
      index = _tablesByZone[zoneId]!.indexWhere((t) => t.id == tableId);
      if (index != -1) targetZoneKey = zoneId;
    }

    if (targetZoneKey == null) {
      for (final entry in _tablesByZone.entries) {
        final idx = entry.value.indexWhere((t) => t.id == tableId);
        if (idx != -1) {
          targetZoneKey = entry.key;
          index = idx;
          break;
        }
      }
    }

    if (targetZoneKey != null && index != -1) {
      final list = _tablesByZone[targetZoneKey]!;
      final old = list[index];
      final updated = old.copyWith(
        posX: posX.clamp(0.0, 0.95),
        posY: posY.clamp(0.0, 0.95),
      );
      list[index] = updated;
      notifyListeners();
    }
  }

  /// Persiste todas las posiciones de la zona actual en Supabase
  Future<void> saveAllPositionsToSupabase(String zoneId) async {
    final list = _tablesByZone[zoneId] ?? [];
    for (final table in list) {
      try {
        await Supabase.instance.client.from('restaurant_tables').upsert({
          'id': table.id,
          'zone_id': table.zoneId,
          'table_number': table.tableNumber,
          'label': table.label,
          'seats': table.seats,
          'shape': table.shape,
          'pos_x': table.posX,
          'pos_y': table.posY,
          'width': table.width,
          'height': table.height,
          'is_structural': table.isStructural,
          'status': table.status,
        });
      } catch (e) {
        debugPrint('⚠️ Error persistiendo mesa ${table.label}: $e');
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
    String? targetZoneKey;
    int index = -1;

    if (_tablesByZone.containsKey(zoneId)) {
      index = _tablesByZone[zoneId]!.indexWhere((t) => t.id == tableId);
      if (index != -1) targetZoneKey = zoneId;
    }

    if (targetZoneKey == null) {
      for (final entry in _tablesByZone.entries) {
        final idx = entry.value.indexWhere((t) => t.id == tableId);
        if (idx != -1) {
          targetZoneKey = entry.key;
          index = idx;
          break;
        }
      }
    }

    if (targetZoneKey != null && index != -1) {
      final list = _tablesByZone[targetZoneKey]!;
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

      list[index] = table.copyWith(
        status: 'occupied',
        assignedWaiter: table.assignedWaiter ?? waiterName,
        activeTickets: updatedTickets,
      );

      notifyListeners();

      final String tableLabel = (table.label != null && table.label!.isNotEmpty)
          ? table.label!
          : (table.shape == 'stool' ? 'Banquillo ${table.tableNumber}' : 'Mesa #${table.tableNumber}');

      try {
        ChargeService? cs = chargeService ?? ChargeService();
        await cs.createOrUpdatePendingChargeForTable(
          tableId: tableId,
          newRoundAmount: amount,
          userId: waiterId,
          roundConcept: concept,
          tableLabel: tableLabel,
        );
      } catch (e) {
        debugPrint('ℹ️ Registro de comanda pendiente offline/test: $e');
      }
    }
  }

  void removeTicketAndCheckFree(String zoneId, String tableId, String ticketId) {
    for (final entry in _tablesByZone.entries) {
      final idx = entry.value.indexWhere((t) => t.id == tableId);
      if (idx != -1) {
        final table = entry.value[idx];
        final updatedTickets = table.activeTickets.where((t) => t['ticket_id'] != ticketId).toList();
        final newStatus = updatedTickets.isEmpty ? 'free' : 'occupied';
        entry.value[idx] = table.copyWith(
          status: newStatus,
          assignedWaiter: updatedTickets.isEmpty ? null : table.assignedWaiter,
          activeTickets: updatedTickets,
        );
        notifyListeners();
        break;
      }
    }
  }

  void clearAllTableTickets(String zoneId, String tableId) {
    for (final entry in _tablesByZone.entries) {
      final idx = entry.value.indexWhere((t) => t.id == tableId);
      if (idx != -1) {
        final table = entry.value[idx];
        entry.value[idx] = table.copyWith(
          status: 'free',
          assignedWaiter: null,
          activeTickets: const [],
        );
        notifyListeners();
        break;
      }
    }
  }
}