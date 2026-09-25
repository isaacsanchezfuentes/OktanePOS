import 'package:flutter/foundation.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';

class TableService {
  final List<ZoneModel> _zones = const [
    ZoneModel(id: 'zone-salon', name: 'Salón Principal', sortOrder: 1),
    ZoneModel(id: 'zone-terraza', name: 'Terraza Exterior', sortOrder: 2),
    ZoneModel(id: 'zone-barra', name: 'Barra / Mostrador', sortOrder: 3),
  ];

  late final Map<String, List<RestaurantTableModel>> _tablesByZone;

  TableService() {
    _initDefaultTables();
  }

  void _initDefaultTables() {
    _tablesByZone = {
      'zone-salon': [
        const RestaurantTableModel(id: 't-1', zoneId: 'zone-salon', tableNumber: 1, seats: 4, shape: 'square', posX: 0.20, posY: 0.25, status: 'occupied', assignedWaiter: 'Carlos (Mesero 1)', activeTickets: [
          {'ticket_id': 'tk-101', 'amount': 250.0, 'concept': 'Mesa 1 - Bebidas', 'waiter_id': 'u-1', 'waiter_name': 'Carlos (Mesero 1)', 'is_peer_support': false}
        ]),
        const RestaurantTableModel(id: 't-2', zoneId: 'zone-salon', tableNumber: 2, seats: 4, shape: 'square', posX: 0.50, posY: 0.25, status: 'free'),
        const RestaurantTableModel(id: 't-3', zoneId: 'zone-salon', tableNumber: 3, seats: 6, shape: 'circle', posX: 0.80, posY: 0.25, status: 'bill_requested', assignedWaiter: 'Ana (Mesero 2)', activeTickets: [
          {'ticket_id': 'tk-102', 'amount': 680.0, 'concept': 'Mesa 3 - Consumo', 'waiter_id': 'u-2', 'waiter_name': 'Ana (Mesero 2)', 'is_peer_support': false}
        ]),
        const RestaurantTableModel(id: 't-4', zoneId: 'zone-salon', tableNumber: 4, seats: 2, shape: 'square', posX: 0.20, posY: 0.65, status: 'free'),
        const RestaurantTableModel(id: 't-5', zoneId: 'zone-salon', tableNumber: 5, seats: 8, shape: 'square', posX: 0.60, posY: 0.65, status: 'free'),
      ],
      'zone-terraza': [
        const RestaurantTableModel(id: 't-10', zoneId: 'zone-terraza', tableNumber: 10, seats: 4, shape: 'circle', posX: 0.30, posY: 0.30, status: 'free'),
        const RestaurantTableModel(id: 't-11', zoneId: 'zone-terraza', tableNumber: 11, seats: 4, shape: 'circle', posX: 0.70, posY: 0.30, status: 'free'),
        const RestaurantTableModel(id: 't-12', zoneId: 'zone-terraza', tableNumber: 12, seats: 6, shape: 'square', posX: 0.50, posY: 0.70, status: 'free'),
      ],
      'zone-barra': [
        const RestaurantTableModel(id: 't-20', zoneId: 'zone-barra', tableNumber: 20, seats: 1, shape: 'bar', posX: 0.25, posY: 0.40, status: 'free'),
        const RestaurantTableModel(id: 't-21', zoneId: 'zone-barra', tableNumber: 21, seats: 1, shape: 'bar', posX: 0.50, posY: 0.40, status: 'free'),
        const RestaurantTableModel(id: 't-22', zoneId: 'zone-barra', tableNumber: 22, seats: 1, shape: 'bar', posX: 0.75, posY: 0.40, status: 'free'),
      ],
    };
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
      }
    }
  }

  void addTicketToTable(
    String zoneId,
    String tableId, {
    required double amount,
    required String concept,
    required String waiterId,
    required String waiterName,
  }) {
    final list = _tablesByZone[zoneId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == tableId);
      if (index != -1) {
        final table = list[index];
        final isPeerSupport = table.assignedWaiter != null && table.assignedWaiter != waiterName;

        final newTicket = {
          'ticket_id': 'tk-${DateTime.now().millisecondsSinceEpoch}',
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
      }
    }
  }
}
