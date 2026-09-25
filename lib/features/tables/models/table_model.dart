class RestaurantTableModel {
  final String id;
  final String zoneId;
  final int tableNumber;
  final int seats;
  final String shape; // 'square', 'circle', 'bar'
  final double posX; // relative 0.0 - 1.0
  final double posY; // relative 0.0 - 1.0
  final String status; // 'free', 'occupied', 'bill_requested'
  final String? assignedWaiter;
  final List<Map<String, dynamic>> activeTickets;

  const RestaurantTableModel({
    required this.id,
    required this.zoneId,
    required this.tableNumber,
    this.seats = 4,
    this.shape = 'square',
    this.posX = 0.5,
    this.posY = 0.5,
    this.status = 'free',
    this.assignedWaiter,
    this.activeTickets = const [],
  });

  RestaurantTableModel copyWith({
    String? id,
    String? zoneId,
    int? tableNumber,
    int? seats,
    String? shape,
    double? posX,
    double? posY,
    String? status,
    String? assignedWaiter,
    List<Map<String, dynamic>>? activeTickets,
  }) {
    return RestaurantTableModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      tableNumber: tableNumber ?? this.tableNumber,
      seats: seats ?? this.seats,
      shape: shape ?? this.shape,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      status: status ?? this.status,
      assignedWaiter: assignedWaiter ?? this.assignedWaiter,
      activeTickets: activeTickets ?? this.activeTickets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone_id': zoneId,
      'table_number': tableNumber,
      'seats': seats,
      'shape': shape,
      'pos_x': posX,
      'pos_y': posY,
      'status': status,
      'assigned_waiter': assignedWaiter,
      'active_tickets': activeTickets,
    };
  }

  factory RestaurantTableModel.fromJson(Map<String, dynamic> json) {
    return RestaurantTableModel(
      id: json['id']?.toString() ?? '',
      zoneId: json['zone_id']?.toString() ?? '',
      tableNumber: (json['table_number'] as num?)?.toInt() ?? 1,
      seats: (json['seats'] as num?)?.toInt() ?? 4,
      shape: json['shape']?.toString() ?? 'square',
      posX: (json['pos_x'] as num?)?.toDouble() ?? 0.5,
      posY: (json['pos_y'] as num?)?.toDouble() ?? 0.5,
      status: json['status']?.toString() ?? 'free',
      assignedWaiter: json['assigned_waiter']?.toString(),
      activeTickets: json['active_tickets'] is List 
          ? List<Map<String, dynamic>>.from(json['active_tickets'])
          : [],
    );
  }
}
